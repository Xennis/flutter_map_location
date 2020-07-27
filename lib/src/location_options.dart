import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';

import 'package:latlong/latlong.dart';

enum LocationServiceStatus {
  disabled,
  permissionDenied,
  subscribed,
  paused,
  unsubscribed,
}

typedef LocationButtonBuilder = Widget Function(BuildContext context,
    ValueNotifier<LocationServiceStatus>, Function onPressed);

typedef LocationMarkerBuilder = Marker Function(
    BuildContext context, LatLng point, ValueNotifier<double> heading);

class LocationOptions extends LayerOptions {
  LocationOptions(
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
  final LocationButtonBuilder buttonBuilder;
  final LocationMarkerBuilder markerBuilder;
  final int updateIntervalMs;
  List<Marker> markers;
}
