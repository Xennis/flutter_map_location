import 'dart:async';

import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map_location/flutter_map_location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationControllerImpl implements LocationController {
  final StreamController<LatLngData> _controller =
      StreamController<LatLngData>.broadcast();
  StreamSubscription<Position>? _onLocationChangedSub;
  StreamSubscription<CompassEvent>? _compassEventsSub;

  bool _isSubscribed = false;

  void dispose() {
    _controller.close();
    _compassEventsSub?.cancel();
    _onLocationChangedSub?.cancel();
  }

  @override
  Future<void> unsubscribe() {
    final List<Future<void>> waitGroup = <Future<void>>[];
    waitGroup.add(unsubscribeCompass());
    waitGroup.add(unsubscribePosition());
    return Future.wait(waitGroup);
  }

  Future<void> unsubscribePosition() {
    if (_onLocationChangedSub != null) {
      _isSubscribed = false;
      return _onLocationChangedSub!.cancel();
    }
    return Future<void>.value();
  }

  Future<void> unsubscribeCompass() {
    if (_compassEventsSub != null) {
      return _compassEventsSub!.cancel();
    }
    return Future<void>.value();
  }

  Future<bool> requestPermissions() async {
    if (await Geolocator.checkPermission() == LocationPermission.denied) {
      if (<LocationPermission>[
            LocationPermission.always,
            LocationPermission.whileInUse
          ].contains(await Geolocator.requestPermission()) ==
          false) {
        return Future<bool>.value(false);
      }
    }
    return Future<bool>.value(true);
  }

  Stream<LatLngData> subscribePosition(
      Duration intervalDuration, LocationAccuracy locationAccuracy) {
    _isSubscribed = true;
    _onLocationChangedSub = Geolocator.getPositionStream(
            intervalDuration: intervalDuration,
            desiredAccuracy: locationAccuracy)
        .listen((Position ld) {
      _controller
          .add(LatLngData(LatLng(ld.latitude, ld.longitude), ld.accuracy));
    }, onError: (Object error) {
      _controller.addError(error);
    }, onDone: () {
      _isSubscribed = false;
      _controller.done;
    });

    return _controller.stream.asBroadcastStream();
  }

  void subscribeCompass(void onData(CompassEvent event)?) {
    _compassEventsSub = FlutterCompass.events?.listen(onData);
  }

  bool isSubscribed() {
    return _isSubscribed;
  }
}
