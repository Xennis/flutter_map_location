import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';

import 'location_layer.dart';
import 'location_options.dart';

class LocationPlugin extends MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream) {
    if (options is LocationOptions) {
      return LocationLayer(options, mapState, stream);
    }
    throw ArgumentError('options is not of type LocationOptions');
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is LocationOptions;
  }
}
