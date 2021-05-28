import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_location/src/types.dart';

enum LocationServiceStatus {
  unkown,
  disabled,
  permissionDenied,
  subscribed,
  paused,
  unsubscribed,
}

typedef LocationButtonBuilder = Widget Function(BuildContext context,
    ValueNotifier<LocationServiceStatus>, Function onPressed);

typedef LocationMarkerBuilder = Marker Function(
    BuildContext context, LatLngData ld, ValueNotifier<double?> heading);

class LocationOptions extends LayerOptions {
  LocationOptions(this.buttonBuilder,
      {this.onLocationUpdate,
      this.onLocationRequested,
      this.markerBuilder,
      this.updateInterval = const Duration(seconds: 1),
      this.initiallyRequest = true})
      : super();

  final void Function(LatLngData?)? onLocationUpdate;
  final void Function(LatLngData?)? onLocationRequested;
  final LocationButtonBuilder buttonBuilder;
  final LocationMarkerBuilder? markerBuilder;
  final Duration updateInterval;
  final bool initiallyRequest;
}
