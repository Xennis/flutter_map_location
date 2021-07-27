import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_compass/flutter_compass.dart' show CompassEvent;
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_location/flutter_map_location.dart';
import 'package:flutter_map_location/src/location_controller.dart';
import 'package:flutter_map_location/src/types.dart';
import 'package:geolocator/geolocator.dart'
    show Geolocator, LocationServiceDisabledException;

import 'location_marker.dart';
import 'location_options.dart';
import 'types.dart';

LocationMarkerBuilder _defaultMarkerBuilder =
    (BuildContext context, LatLngData ld, ValueNotifier<double?> heading) {
  final double diameter = ld.highAccuracy() ? 60.0 : 120.0;
  return Marker(
    point: ld.location,
    builder: (_) => LocationMarker(ld, heading),
    height: diameter,
    width: diameter,
    rotate: false,
  );
};

class LocationLayer extends StatefulWidget {
  const LocationLayer(this.options, this.map, this.stream, {Key? key})
      : super(key: key);

  final LocationOptions options;
  final MapState map;
  final Stream<Null> stream;

  @override
  _LocationLayerState createState() => _LocationLayerState();
}

class _LocationLayerState extends State<LocationLayer>
    with WidgetsBindingObserver {
  final ValueNotifier<LocationServiceStatus> _serviceStatus =
      ValueNotifier<LocationServiceStatus>(LocationServiceStatus.unknown);
  final ValueNotifier<LatLngData?> _location = ValueNotifier<LatLngData?>(null);
  final ValueNotifier<double?> _heading = ValueNotifier<double?>(null);
  late final LocationControllerImpl _controller;

  StreamSubscription<LatLngData>? _locationSub;
  bool _locationRequested = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.options.controller as LocationControllerImpl? ??
        LocationController() as LocationControllerImpl;
    WidgetsBinding.instance?.addObserver(this);
    if (widget.options.initiallyRequest) {
      _locationRequested = true;
      _initOnLocationUpdateSubscription();
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _controller.dispose();
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
        _controller.unsubscribeCompass();
        _controller.unsubscribePosition();
        if (_serviceStatus.value == LocationServiceStatus.subscribed) {
          _serviceStatus.value = LocationServiceStatus.paused;
        } else {
          _serviceStatus.value = LocationServiceStatus.unknown;
        }
        break;
      case AppLifecycleState.resumed:
        if (_serviceStatus.value == LocationServiceStatus.paused) {
          _serviceStatus.value = LocationServiceStatus.unknown;
          _initOnLocationUpdateSubscription();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Stack(
      children: <Widget>[
        ValueListenableBuilder<LatLngData?>(
            valueListenable: _location,
            builder: (BuildContext context, LatLngData? ld, Widget? child) {
              if (ld == null) {
                return Container();
              }
              final LocationMarkerBuilder? customBuilder =
                  widget.options.markerBuilder;
              final Marker marker = customBuilder != null
                  ? customBuilder(context, ld, _heading)
                  : _defaultMarkerBuilder(context, ld, _heading);
              return MarkerLayerWidget(
                  options: MarkerLayerOptions(markers: <Marker>[marker]));
            }),
        widget.options.buttonBuilder(context, _serviceStatus, () async {
          // Check if there is no location subscription, no location value or the location service is off.
          if (!_controller.isSubscribed() ||
              !await Geolocator.isLocationServiceEnabled()) {
            _initOnLocationUpdateSubscription();
            _locationRequested = true;
            return;
          }

          widget.options.onLocationRequested?.call(_location.value);
        })
      ],
    ));
  }

  // ignore: avoid_void_async
  void _initOnLocationUpdateSubscription() async {
    if (!await _controller.requestPermissions()) {
      _serviceStatus.value = LocationServiceStatus.permissionDenied;
      return;
    }

    await _locationSub?.cancel();
    await _controller.unsubscribePosition();
    _locationSub = _controller
        .subscribePosition(
            widget.options.updateInterval, widget.options.locationAccuracy)
        .listen((LatLngData loc) {
      _location.value = loc;
      widget.options.onLocationUpdate?.call(loc);
      if (_locationRequested) {
        _locationRequested = false;
        widget.options.onLocationRequested?.call(loc);
      }
    }, onError: (Object error) {
      if (error is LocationServiceDisabledException) {
        _serviceStatus.value = LocationServiceStatus.disabled;
      } else {
        _serviceStatus.value = LocationServiceStatus.unsubscribed;
      }
    }, onDone: () {
      _serviceStatus.value = LocationServiceStatus.unsubscribed;
    });

    await _controller.unsubscribeCompass();
    _controller.subscribeCompass((CompassEvent event) {
      _heading.value = event.heading;
    });

    _serviceStatus.value = LocationServiceStatus.subscribed;
  }
}
