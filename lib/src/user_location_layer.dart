import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_user_location/src/user_location_marker.dart';
import 'package:flutter_map_user_location/src/user_location_options.dart';
import 'package:location/location.dart';
import 'package:latlong/latlong.dart';

UserLocationMarkerBuilder _defaultMarkerBuilder =
    (BuildContext context, LatLng point, ValueNotifier<double> heading) {
  return Marker(
    point: point,
    builder: (_) => UserLocationMarker(heading: heading),
    height: 60.0,
    width: 60.0,
  );
};

class UserLocationLayer extends StatefulWidget {
  const UserLocationLayer(
      {Key key, @required this.options, this.map, this.stream})
      : assert(options != null),
        super(key: key);

  final UserLocationOptions options;
  final MapState map;
  final Stream<void> stream;

  @override
  _UserLocationLayerState createState() => _UserLocationLayerState();
}

class _UserLocationLayerState extends State<UserLocationLayer>
    with WidgetsBindingObserver {
  final Location _location = Location();
  final ValueNotifier<UserLocationServiceStatus> _serviceStatus =
      ValueNotifier<UserLocationServiceStatus>(null);
  final ValueNotifier<LatLng> _lastLocation = ValueNotifier<LatLng>(null);
  final ValueNotifier<double> _heading = ValueNotifier<double>(null);

  StreamSubscription<LocationData> _onLocationChangedSub;
  StreamSubscription<double> _compassEventsSub;
  bool _locationRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _location.changeSettings(interval: widget.options.updateIntervalMs);
    _locationRequested = true;
    _initOnLocationUpdateSubscription().then(
        (UserLocationServiceStatus status) => _serviceStatus.value = status);
    _lastLocation.addListener(() {
      final LatLng loc = _lastLocation.value;
      widget.options.onLocationUpdate?.call(loc);
      if (widget.options.markers.isNotEmpty) {
        widget.options.markers.removeLast();
      }
      if (loc == null) {
        return;
      }
      widget.options.markers.add(widget.options.markerBuilder != null
          ? widget.options.markerBuilder(context, loc, _heading)
          : _defaultMarkerBuilder(context, loc, _heading));
      if (_locationRequested) {
        _locationRequested = false;
        widget.options.onLocationRequested?.call(loc);
      }
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
        if (_serviceStatus?.value == UserLocationServiceStatus.subscribed) {
          _serviceStatus.value = UserLocationServiceStatus.paused;
        } else {
          _serviceStatus.value = null;
        }
        break;
      case AppLifecycleState.resumed:
        if (_serviceStatus?.value == UserLocationServiceStatus.paused) {
          _serviceStatus.value = null;
          _initOnLocationUpdateSubscription().then(
              (UserLocationServiceStatus value) =>
                  _serviceStatus.value = value);
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.options.buttonBuilder(context, _serviceStatus, () async {
      if (_serviceStatus?.value == UserLocationServiceStatus.disabled) {
        if (!await _location.requestService()) {
          return;
        }
        _serviceStatus.value = null;
      }
      if (_serviceStatus?.value != UserLocationServiceStatus.subscribed ||
          _lastLocation?.value == null ||
          !await _location.serviceEnabled()) {
        _initOnLocationUpdateSubscription().then(
            (UserLocationServiceStatus value) => _serviceStatus.value = value);
        _locationRequested = true;
      } else {
        widget.options.onLocationRequested?.call(_lastLocation.value);
      }
    });
  }

  Future<UserLocationServiceStatus> _initOnLocationUpdateSubscription() async {
    if (!await _location.serviceEnabled()) {
      _lastLocation.value = null;
      return UserLocationServiceStatus.disabled;
    }
    if (await _location.hasPermission() == PermissionStatus.denied) {
      if (await _location.requestPermission() != PermissionStatus.granted) {
        _lastLocation.value = null;
        return UserLocationServiceStatus.permissionDenied;
      }
    }
    await _onLocationChangedSub?.cancel();
    _onLocationChangedSub =
        _location.onLocationChanged.listen((LocationData ld) {
      _lastLocation.value = _locationDataToLatLng(ld);
    }, onError: (Object error) {
      _lastLocation.value = null;
      _serviceStatus.value = UserLocationServiceStatus.unsubscribed;
    }, onDone: () {
      _lastLocation.value = null;
      _serviceStatus.value = UserLocationServiceStatus.unsubscribed;
    });
    await _compassEventsSub?.cancel();
    _compassEventsSub = FlutterCompass.events.listen((double heading) {
      _heading.value = heading;
    });
    return UserLocationServiceStatus.subscribed;
  }
}

LatLng _locationDataToLatLng(LocationData ld) {
  if (ld.latitude == null || ld.longitude == null) {
    return null;
  }
  return LatLng(ld.latitude, ld.longitude);
}
