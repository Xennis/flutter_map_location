library flutter_map_location;

import 'package:flutter_map_location/src/location_controller.dart';

export 'src/location_layer.dart';
export 'src/location_marker.dart';
export 'src/location_options.dart';
export 'src/location_plugin.dart';
export 'src/types.dart';

/// Controller to programmatically interact with [LocationPlugin].
abstract class LocationController {
  factory LocationController() => LocationControllerImpl();

  /// Unsubscribe from location subscription.
  Future<void> unsubscribe();
}
