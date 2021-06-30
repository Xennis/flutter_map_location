import 'dart:async';

import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map_location/flutter_map_location.dart';
import 'package:geolocator/geolocator.dart';

class LocationControllerImpl implements LocationController {
  StreamSubscription<Position>? _onLocationChangedSub;
  StreamSubscription<CompassEvent>? _compassEventsSub;

  bool _isSubscribed = false;

  void dispose() {
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

  void subscribePosition(
      Duration intervalDuration, void onData(Position event)?,
      {Function? onError, void onDone()?}) {
    _isSubscribed = true;
    _onLocationChangedSub =
        Geolocator.getPositionStream(intervalDuration: intervalDuration)
            .listen(onData, onError: (Object error) {
      _isSubscribed = false;
      if (onError != null) {
        onError();
      }
    }, onDone: () {
      _isSubscribed = false;
      if (onDone != null) {
        onDone();
      }
    });
  }

  void subscribeCompass(void onData(CompassEvent event)?) {
    _compassEventsSub = FlutterCompass.events?.listen(onData);
  }

  bool isSubscribed() {
    return _isSubscribed;
  }
}
