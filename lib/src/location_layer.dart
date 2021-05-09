import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_location/src/types.dart';
import 'package:location/location.dart';
import 'package:latlong/latlong.dart';

import 'location_marker.dart';
import 'location_options.dart';

LocationMarkerBuilder _defaultMarkerBuilder =
    (BuildContext context, LatLngData ld, ValueNotifier<double> heading) {
  final double diameter = ld != null && ld.highAccurency() ? 60.0 : 120.0;
  return Marker(
    point: ld.location,
    builder: (_) => LocationMarker(ld: ld, heading: heading),
    height: diameter,
    width: diameter,
  );
};

class LocationLayer extends StatefulWidget {
  const LocationLayer({Key key, @required this.options, this.map, this.stream})
      : assert(options != null),
        super(key: key);

  final LocationOptions options;
  final MapState map;
  final Stream<Null> stream;

  @override
  _LocationLayerState createState() => _LocationLayerState();
}

class _LocationLayerState extends State<LocationLayer>
    with WidgetsBindingObserver {
  final Location _location = Location();
  final ValueNotifier<LocationServiceStatus> _serviceStatus =
      ValueNotifier<LocationServiceStatus>(null);
  final ValueNotifier<LatLngData> _lastLocation =
      ValueNotifier<LatLngData>(null);
  final ValueNotifier<double> _heading = ValueNotifier<double>(null);

  StreamSubscription<LocationData> _onLocationChangedSub;
  StreamSubscription<CompassEvent> _compassEventsSub;
  bool _locationRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _location.changeSettings(interval: widget.options.updateIntervalMs);
    _locationRequested = true;
    _initOnLocationUpdateSubscription()
        .then((LocationServiceStatus status) => _serviceStatus.value = status);
    _lastLocation.addListener(() {
      final LatLngData loc = _lastLocation.value;
      widget.options.onLocationUpdate?.call(loc);
      if (loc == null || loc.location == null) {
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
        _compassEventsSub?.cancel();
        _onLocationChangedSub?.cancel();
        if (_serviceStatus?.value == LocationServiceStatus.subscribed) {
          _serviceStatus.value = LocationServiceStatus.paused;
        } else {
          _serviceStatus.value = null;
        }
        break;
      case AppLifecycleState.resumed:
        if (_serviceStatus?.value == LocationServiceStatus.paused) {
          _serviceStatus.value = null;
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
        ValueListenableBuilder<LatLngData>(
            valueListenable: _lastLocation,
            builder: (BuildContext context, LatLngData ld, Widget child) {
              if (ld?.location == null) {
                return Container();
              }
              final Marker marker = widget.options.markerBuilder != null
                  ? widget.options
                      .markerBuilder(context, _lastLocation.value, _heading)
                  : _defaultMarkerBuilder(
                      context, _lastLocation.value, _heading);
              return MarkerLayerWidget(
                  options: MarkerLayerOptions(markers: <Marker>[marker]));
            }),
        widget.options.buttonBuilder(context, _serviceStatus, () async {
          if (_serviceStatus?.value == LocationServiceStatus.disabled) {
            if (!await _location.requestService()) {
              return;
            }
            _serviceStatus.value = null;
          }
          if (_serviceStatus?.value != LocationServiceStatus.subscribed ||
              _lastLocation?.value == null ||
              !await _location.serviceEnabled()) {
            _initOnLocationUpdateSubscription().then(
                (LocationServiceStatus value) => _serviceStatus.value = value);
            _locationRequested = true;
          } else {
            widget.options.onLocationRequested?.call(_lastLocation.value);
          }
        })
      ],
    ));
  }

  Future<LocationServiceStatus> _initOnLocationUpdateSubscription() async {
    if (!await _location.serviceEnabled()) {
      _lastLocation.value = null;
      return LocationServiceStatus.disabled;
    }
    if (await _location.hasPermission() == PermissionStatus.denied) {
      if (await _location.requestPermission() != PermissionStatus.granted) {
        _lastLocation.value = null;
        return LocationServiceStatus.permissionDenied;
      }
    }
    await _onLocationChangedSub?.cancel();
    _onLocationChangedSub =
        _location.onLocationChanged.listen((LocationData ld) {
      _lastLocation.value = _locationDataToLatLng(ld);
    }, onError: (Object error) {
      _lastLocation.value = null;
      _serviceStatus.value = LocationServiceStatus.unsubscribed;
    }, onDone: () {
      _lastLocation.value = null;
      _serviceStatus.value = LocationServiceStatus.unsubscribed;
    });
    await _compassEventsSub?.cancel();
    _compassEventsSub = FlutterCompass.events.listen((CompassEvent event) {
      _heading.value = event.heading;
    });
    return LocationServiceStatus.subscribed;
  }
}

LatLngData _locationDataToLatLng(LocationData ld) {
  if (ld.latitude == null || ld.longitude == null) {
    return null;
  }
  return LatLngData(LatLng(ld.latitude, ld.longitude), ld.accuracy);
}
