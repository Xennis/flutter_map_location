import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_compass/flutter_compass.dart' show CompassEvent;
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_location/flutter_map_location.dart';
import 'package:flutter_map_location/src/location_controller.dart';
import 'package:flutter_map_location/src/types.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'
    show
        Geolocator,
        Position,
        LocationPermission,
        LocationServiceDisabledException;

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
      ValueNotifier<LocationServiceStatus>(LocationServiceStatus.unkown);
  final ValueNotifier<LatLngData?> _location = ValueNotifier<LatLngData?>(null);
  final ValueNotifier<double?> _heading = ValueNotifier<double?>(null);
  late final LocationControllerImpl _controller;

  bool _locationRequested = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.options.controller as LocationControllerImpl? ??
        LocationController() as LocationControllerImpl;
    WidgetsBinding.instance?.addObserver(this);
    if (widget.options.initiallyRequest) {
      _locationRequested = true;
      _initOnLocationUpdateSubscription().then((LocationServiceStatus status) {
        _serviceStatus.value = status;
      });
    }
    _location.addListener(() {
      final LatLngData? loc = _location.value;
      widget.options.onLocationUpdate?.call(loc);
      if (loc == null) {
        return;
      }
      if (_locationRequested) {
        _locationRequested = false;
        widget.options.onLocationRequested?.call(loc);
      }
      //setState(() {});
    });
  }

  @override
  void dispose() {
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
          _serviceStatus.value = LocationServiceStatus.unkown;
        }
        break;
      case AppLifecycleState.resumed:
        if (_serviceStatus.value == LocationServiceStatus.paused) {
          _serviceStatus.value = LocationServiceStatus.unkown;
          _initOnLocationUpdateSubscription().then(
              (LocationServiceStatus value) => _serviceStatus.value = value);
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
              _location.value == null ||
              !await Geolocator.isLocationServiceEnabled()) {
            _initOnLocationUpdateSubscription(forceRequestLocation: true).then(
                (LocationServiceStatus value) => _serviceStatus.value = value);
            _locationRequested = true;
            return;
          }

          widget.options.onLocationRequested?.call(_location.value);
        })
      ],
    ));
  }

  Future<LocationServiceStatus> _initOnLocationUpdateSubscription(
      {bool forceRequestLocation = false}) async {
    if (await Geolocator.checkPermission() == LocationPermission.denied) {
      if (widget.options.initiallyRequest || forceRequestLocation) {
        if (<LocationPermission>[
              LocationPermission.always,
              LocationPermission.whileInUse
            ].contains(await Geolocator.requestPermission()) ==
            false) {
          _location.value = null;
          return LocationServiceStatus.permissionDenied;
        }
      }
    }

    await _controller.unsubscribePosition();
    _controller.subscribePosition(widget.options.updateInterval, (Position ld) {
      _location.value = _locationDataToLatLng(ld);
    }, onError: (Object error) {
      _location.value = null;
      if (error is LocationServiceDisabledException) {
        _serviceStatus.value = LocationServiceStatus.disabled;
      } else {
        _serviceStatus.value = LocationServiceStatus.unsubscribed;
      }
    }, onDone: () {
      _location.value = null;
      _serviceStatus.value = LocationServiceStatus.unsubscribed;
    });

    await _controller.unsubscribeCompass();
    _controller.subscribeCompass((CompassEvent event) {
      _heading.value = event.heading;
    });

    return LocationServiceStatus.subscribed;
  }
}

LatLngData _locationDataToLatLng(Position ld) {
  return LatLngData(LatLng(ld.latitude, ld.longitude), ld.accuracy);
}
