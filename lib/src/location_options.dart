import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_location/flutter_map_location.dart';
import 'package:flutter_map_location/src/location_controller.dart';
import 'package:flutter_map_location/src/types.dart';
import 'package:geolocator/geolocator.dart';

enum LocationServiceStatus {
  unknown,
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
      LocationController? controller,
      this.updateInterval = const Duration(seconds: 1),
      this.initiallyRequest = true,
      this.locationAccuracy = LocationAccuracy.best})
      : controller = controller ?? LocationControllerImpl(),
        super();

  /// If the LocationController is provided it can be used to programmatically access
  /// the functions of the plugin.
  final LocationController controller;
  final void Function(LatLngData?)? onLocationUpdate;
  final void Function(LatLngData?)? onLocationRequested;
  final LocationButtonBuilder buttonBuilder;
  final LocationMarkerBuilder? markerBuilder;
  final Duration updateInterval;
  final LocationAccuracy locationAccuracy;
  final bool initiallyRequest;
}
