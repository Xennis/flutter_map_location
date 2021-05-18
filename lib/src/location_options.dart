import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_location/src/types.dart';

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
    BuildContext context, LatLngData ld, ValueNotifier<double> heading);

class LocationOptions extends LayerOptions {
  LocationOptions(
      {this.onLocationUpdate,
      this.onLocationRequested,
      @required this.buttonBuilder,
      this.markerBuilder,
      this.updateInterval = const Duration(seconds: 1),
      this.initiallyRequest = true})
      : assert(buttonBuilder != null),
        super();

  final void Function(LatLngData) onLocationUpdate;
  final void Function(LatLngData) onLocationRequested;
  final LocationButtonBuilder buttonBuilder;
  final LocationMarkerBuilder markerBuilder;
  final Duration updateInterval;
  final bool initiallyRequest;
}
