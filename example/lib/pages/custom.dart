import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location/flutter_map_location.dart';

import '../widgets/drawer.dart';

class CustomPage extends StatefulWidget {
  static const String route = 'custom';

  @override
  _CustomPageState createState() => _CustomPageState();
}

class _CustomPageState extends State<CustomPage> {
  final MapController mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Customized'),
        ),
        drawer: buildDrawer(context, CustomPage.route),
        body: Center(
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              plugins: <MapPlugin>[
                LocationPlugin(),
              ],
              interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            layers: <LayerOptions>[
              TileLayerOptions(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: <String>['a', 'b', 'c'],
              ),
              LocationOptions(
                onLocationUpdate: (LatLngData ld) {
                  print(
                      'Location updated: ${ld?.location} (accuracy: ${ld?.accuracy})');
                },
                onLocationRequested: (LatLngData ld) {
                  if (ld == null || ld.location == null) {
                    return;
                  }
                  mapController?.move(ld.location, 16.0);
                },
                buttonBuilder: (BuildContext context,
                    ValueNotifier<LocationServiceStatus> status,
                    Function onPressed) {
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: FloatingActionButton(
                          backgroundColor: Colors.pink,
                          child: const Icon(
                            Icons.home,
                            color: Colors.black,
                          ),
                          onPressed: () => onPressed()),
                    ),
                  );
                },
                markerBuilder: (BuildContext context, LatLngData ld,
                    ValueNotifier<double> heading) {
                  return Marker(
                    point: ld.location,
                    builder: (_) => Container(
                      child: Column(
                        children: <Widget>[
                          Stack(
                            alignment: AlignmentDirectional.center,
                            children: <Widget>[
                              Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.pink[300].withOpacity(0.7)),
                                height: 40.0,
                                width: 40.0,
                              ),
                              const Icon(
                                Icons.location_city,
                                size: 30.0,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    height: 60.0,
                    width: 60.0,
                  );
                },
              ),
            ],
          ),
        ));
  }
}
