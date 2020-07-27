import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';

import 'package:latlong/latlong.dart';

enum UserLocationServiceStatus {
  disabled,
  permissionDenied,
  subscribed,
  paused,
  unsubscribed,
}

typedef UserLocationButtonBuilder = Widget Function(BuildContext context,
    ValueNotifier<UserLocationServiceStatus>, Function onPressed);

typedef UserLocationMarkerBuilder = Marker Function(
    BuildContext context, LatLng point, ValueNotifier<double> heading);

class UserLocationOptions extends LayerOptions {
  UserLocationOptions(
      {@required this.markers,
      this.onLocationUpdate,
      this.onLocationRequested,
      @required this.buttonBuilder,
      this.markerBuilder,
      this.updateIntervalMs = 1000})
      : assert(markers != null, buttonBuilder != null),
        super();

  final void Function(LatLng) onLocationUpdate;
  final void Function(LatLng) onLocationRequested;
  final UserLocationButtonBuilder buttonBuilder;
  final UserLocationMarkerBuilder markerBuilder;
  final int updateIntervalMs;
  List<Marker> markers;
}
