import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/plugin_api.dart';
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
  final ValueNotifier<LatLngData?> _lastLocation =
      ValueNotifier<LatLngData?>(null);
  final ValueNotifier<double?> _heading = ValueNotifier<double?>(null);

  StreamSubscription<Position>? _onLocationChangedSub;
  StreamSubscription<CompassEvent>? _compassEventsSub;
  bool _locationRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    if (widget.options.initiallyRequest) {
      _locationRequested = true;
      _initOnLocationUpdateSubscription().then((LocationServiceStatus status) {
        _serviceStatus.value = status;
      });
    }
    _lastLocation.addListener(() {
      final LatLngData? loc = _lastLocation.value;
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
    _compassEventsSub?.cancel();
    _onLocationChangedSub?.cancel();
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
        _compassEventsSub?.cancel();
        _onLocationChangedSub?.cancel();
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
            valueListenable: _lastLocation,
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
          if (_serviceStatus.value != LocationServiceStatus.subscribed ||
              _lastLocation.value == null ||
              !await Geolocator.isLocationServiceEnabled()) {
            _initOnLocationUpdateSubscription(forceRequestLocation: true).then(
                (LocationServiceStatus value) => _serviceStatus.value = value);
            _locationRequested = true;
            return;
          }

          widget.options.onLocationRequested?.call(_lastLocation.value);
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
          _lastLocation.value = null;
          return LocationServiceStatus.permissionDenied;
        }
      }
    }

    await _onLocationChangedSub?.cancel();

    _onLocationChangedSub = Geolocator.getPositionStream(
            intervalDuration: widget.options.updateInterval)
        .listen((Position ld) {
      _lastLocation.value = _locationDataToLatLng(ld);
    }, onError: (Object error) {
      _lastLocation.value = null;
      if (error is LocationServiceDisabledException) {
        _serviceStatus.value = LocationServiceStatus.disabled;
      } else {
        _serviceStatus.value = LocationServiceStatus.unsubscribed;
      }
    }, onDone: () {
      _lastLocation.value = null;
      _serviceStatus.value = LocationServiceStatus.unsubscribed;
    });
    await _compassEventsSub?.cancel();
    _compassEventsSub = FlutterCompass.events?.listen((CompassEvent event) {
      _heading.value = event.heading;
    });
    return LocationServiceStatus.subscribed;
  }
}

LatLngData _locationDataToLatLng(Position ld) {
  return LatLngData(LatLng(ld.latitude, ld.longitude), ld.accuracy);
}
