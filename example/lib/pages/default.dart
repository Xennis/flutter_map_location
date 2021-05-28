import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location/flutter_map_location.dart';

import '../widgets/drawer.dart';

class DefaultPage extends StatefulWidget {
  static const String route = '/';

  @override
  _DefaultPageState createState() => _DefaultPageState();
}

class _DefaultPageState extends State<DefaultPage> {
  // USAGE NOTE 1: Add a controler and marker list:
  final MapController mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Default'),
        ),
        drawer: buildDrawer(context, DefaultPage.route),
        body: Center(
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              plugins: <MapPlugin>[
                // USAGE NOTE 2: Add the plugin
                LocationPlugin(),
              ],
            ),
            layers: <LayerOptions>[
              TileLayerOptions(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: <String>['a', 'b', 'c'],
              ),
            ],
            nonRotatedLayers: <LayerOptions>[
              // USAGE NOTE 3: Add the options for the plugin
              LocationOptions(
                locationButton(),
                onLocationUpdate: (LatLngData? ld) {
                  print(
                      'Location updated: ${ld?.location} (accuracy: ${ld?.accuracy})');
                },
                onLocationRequested: (LatLngData? ld) {
                  if (ld == null) {
                    return;
                  }
                  mapController.move(ld.location, 16.0);
                },
              ),
            ],
          ),
        ));
  }

  LocationButtonBuilder locationButton() {
    return (BuildContext context, ValueNotifier<LocationServiceStatus> status,
        Function onPressed) {
      return Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
          child: FloatingActionButton(
              child: ValueListenableBuilder<LocationServiceStatus>(
                  valueListenable: status,
                  builder: (BuildContext context, LocationServiceStatus value,
                      Widget? child) {
                    switch (value) {
                      case LocationServiceStatus.disabled:
                      case LocationServiceStatus.permissionDenied:
                      case LocationServiceStatus.unsubscribed:
                        return const Icon(
                          Icons.location_disabled,
                          color: Colors.white,
                        );
                      default:
                        return const Icon(
                          Icons.location_searching,
                          color: Colors.white,
                        );
                    }
                  }),
              onPressed: () => onPressed()),
        ),
      );
    };
  }
}
