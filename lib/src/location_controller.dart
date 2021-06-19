import 'dart:async';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart'
    show CompassEvent, FlutterCompass;
import 'package:geolocator/geolocator.dart'
    show
        Geolocator,
        Position,
        LocationPermission,
        LocationServiceDisabledException;

import 'package:latlong2/latlong.dart';

import '../flutter_map_location.dart';

class LocationController {
  final StreamController<LatLngData> _controller = StreamController<LatLngData>();
  StreamSubscription<Position>? _onLocationChangedSub;
  StreamSubscription<CompassEvent>? _compassEventsSub;

  LocationServiceStatus _status = LocationServiceStatus.unkown;
  Position? _position;
  CompassEvent? _heading;

  //ValueNotifier<double?> get heading => _heading;

  //ValueNotifier<LatLngData?> get location=> _location;

  //ValueNotifier<LocationServiceStatus> get status => _serviceStatus;

  void dispose() {
    _controller?.close();
    _onLocationChangedSub?.cancel();
    _compassEventsSub?.cancel();
    _status = LocationServiceStatus.unkown;
  }

  Future<bool> requestPermissions() async {
    if (await Geolocator.checkPermission() == LocationPermission.denied) {
      if (<LocationPermission>[
            LocationPermission.always,
            LocationPermission.whileInUse
          ].contains(await Geolocator.requestPermission()) ==
          false) {
        _position = null;
        _status = LocationServiceStatus.permissionDenied;
        return Future<bool>.value(false);
      }
    }
    return Future<bool>.value(true);
  }

  Future<bool> noSub() {
    // Check if there is no location subscription, no location value or the location service is off.
    if (_status != LocationServiceStatus.subscribed || _position == null) {
      return Future<bool>.value(false);
    }
    return Geolocator.isLocationServiceEnabled().then((bool value) => !value);
  }

  Stream<LatLngData> subscribe(Duration intervalDuration) {
    _onLocationChangedSub =
        Geolocator.getPositionStream(intervalDuration: intervalDuration).listen(
            (Position ld) {
      _controller.add(LatLngData(
          LatLng(ld.latitude, ld.longitude), ld.accuracy, _heading?.heading));
      _position = ld;
    }, onError: (Object error) {
      _position = null;
      if (error is LocationServiceDisabledException) {
        _status = LocationServiceStatus.disabled;
      } else {
        _status = LocationServiceStatus.unsubscribed;
      }
      _controller.addError(error);
    }, onDone: () {
      _position = null;
      _status = LocationServiceStatus.unsubscribed;
      _controller.done;
    });

    _compassEventsSub = FlutterCompass.events?.listen((CompassEvent event) {
      if (_position != null) {
        _controller.add(LatLngData(
            LatLng(_position!.latitude, _position!.longitude),
            _position!.accuracy,
            event.heading));
      }
      _heading = event;
    }, onError: (Object error) {
      if (_position != null) {
        _controller.add(LatLngData(
            LatLng(_position!.latitude, _position!.longitude),
            _position!.accuracy,
            null));
      }
      _heading = null;
    }, onDone: () {
      if (_position != null) {
        _controller.add(LatLngData(
            LatLng(_position!.latitude, _position!.longitude),
            _position!.accuracy,
            null));
      }
      _heading = null;
    });

    _status = LocationServiceStatus.subscribed;
    return _controller.stream;
  }

  Future<void> unsubscribe() {
    final List<Future<void>> waitGroup = <Future<void>>[];
    if (_onLocationChangedSub != null) {
      waitGroup.add(_onLocationChangedSub!.cancel());
    }
    if (_compassEventsSub != null) {
      waitGroup.add(_compassEventsSub!.cancel());
    }
    // Reset status
    _status = LocationServiceStatus.unkown;
    return Future.wait(waitGroup);
  }
}
