import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_compass/flutter_compass.dart'
    show CompassEvent, FlutterCompass;
import 'package:flutter_map/plugin_api.dart';
import 'package:geolocator/geolocator.dart'
    show
        Geolocator,
        Position,
        LocationPermission,
        LocationServiceDisabledException;
import 'package:latlong2/latlong.dart';

import 'location_marker.dart';
import 'location_options.dart';
import 'types.dart';

LocationMarkerBuilder _defaultMarkerBuilder =
    (BuildContext context, LatLngData? ld, ValueNotifier<double?> heading) {
  final double diameter = ld != null && ld.highAccurency() ? 60.0 : 120.0;
  return Marker(
    point: ld!.location,
    builder: (_) => LocationMarker(ld: ld, heading: heading),
    height: diameter,
    width: diameter,
  );
};

class LocationLayer extends StatefulWidget {
  const LocationLayer({Key? key, required this.options, this.map, this.stream})
      : super(key: key);

  final LocationOptions options;
  final MapState? map;
  final Stream<Null>? stream;

  @override
  _LocationLayerState createState() => _LocationLayerState();
}

class _LocationLayerState extends State<LocationLayer>
    with WidgetsBindingObserver {
  final ValueNotifier<LocationServiceStatus?> _serviceStatus =
      ValueNotifier<LocationServiceStatus?>(null);
  final ValueNotifier<LatLngData?> _location = ValueNotifier<LatLngData?>(null);
  final ValueNotifier<double?> _heading = ValueNotifier<double?>(null);

  StreamSubscription<Position>? _onLocationChangedSub;
  StreamSubscription<CompassEvent>? _compassEventsSub;
  bool _locationRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
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
    _compassEventsSub?.cancel();
    _onLocationChangedSub?.cancel();
    WidgetsBinding.instance!.removeObserver(this);
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
          _serviceStatus.value = null;
        }
        break;
      case AppLifecycleState.resumed:
        if (_serviceStatus.value == LocationServiceStatus.paused) {
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
        ValueListenableBuilder<LatLngData?>(
            valueListenable: _location,
            builder: (BuildContext context, LatLngData? ld, Widget? child) {
              if (ld?.location == null) {
                return Container();
              }
              final Marker marker = widget.options.markerBuilder != null
                  ? widget.options.markerBuilder!(
                      context, _location.value, _heading)
                  : _defaultMarkerBuilder(context, _location.value, _heading);
              return MarkerLayerWidget(
                  options: MarkerLayerOptions(markers: <Marker>[marker]));
            }),
        widget.options.buttonBuilder(context, _serviceStatus, () async {
          // Check if there is no location subscription, no location value or the location service is off.
          if (_serviceStatus.value != LocationServiceStatus.subscribed ||
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

    await _onLocationChangedSub?.cancel();
    _onLocationChangedSub = Geolocator.getPositionStream(
      intervalDuration: widget.options.updateInterval,
    ).listen((Position ld) {
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

    await _compassEventsSub?.cancel();
    _compassEventsSub = FlutterCompass.events!.listen((CompassEvent event) {
      _heading.value = event.heading;
    });

    return LocationServiceStatus.subscribed;
  }
}

LatLngData _locationDataToLatLng(Position ld) {
  return LatLngData(LatLng(ld.latitude, ld.longitude), ld.accuracy);
}
