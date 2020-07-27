import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_user_location/src/user_location_layer.dart';
import 'package:flutter_map_user_location/src/user_location_options.dart';

class UserLocationPlugin extends MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<void> stream) {
    if (options is UserLocationOptions) {
      return UserLocationLayer(options: options, map: mapState, stream: stream);
    }
    throw ArgumentError('options is not of type UserLocationOptions');
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is UserLocationOptions;
  }
}
