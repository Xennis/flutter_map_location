import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location/flutter_map_location.dart';

import '../widgets/drawer.dart';

class ControllerPage extends StatefulWidget {
  static const String route = 'controller';

  @override
  _ControllerPageState createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  final MapController _mapController = MapController();
  final LocationController _locationController = LocationController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Controller'),
        ),
        drawer: buildDrawer(context, ControllerPage.route),
        body: Center(
            child: Column(children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    print('Unsubscribe');
                    _locationController.unsubscribe();
                  },
                  child: const Text('Unsubscribe'),
                )
              ],
            ),
          ),
          Flexible(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                plugins: <MapPlugin>[
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
                LocationOptions(
                  locationButton(),
                  controller: _locationController,
                  onLocationUpdate: (LatLngData? ld) {
                    print(
                        'Location updated: ${ld?.location} (accuracy: ${ld?.accuracy})');
                  },
                  onLocationRequested: (LatLngData? ld) {
                    if (ld == null) {
                      return;
                    }
                    _mapController.move(ld.location, 16.0);
                  },
                ),
              ],
            ),
          )
        ])));
  }

  LocationButtonBuilder locationButton() {
    return (BuildContext context, ValueNotifier<LocationServiceStatus> status,
        Function onPressed) {
      return Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
          child: FloatingActionButton(
              child: const Icon(
                Icons.location_searching,
                color: Colors.white,
              ),
              onPressed: () {
                log('Subscribe');
                onPressed();
              }),
        ),
      );
    };
  }
}
