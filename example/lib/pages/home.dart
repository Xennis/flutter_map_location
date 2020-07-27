import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map_user_location/flutter_map_user_location.dart';

class HomePage extends StatelessWidget {
  final MapController mapController = MapController();
  final List<Marker> userLocationMarkers = <Marker>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('User Location Examples'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Flexible(
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    plugins: <MapPlugin>[
                      UserLocationPlugin(),
                    ],
                  ),
                  layers: <LayerOptions>[
                    TileLayerOptions(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: <String>['a', 'b', 'c'],
                      tileProvider: NonCachingNetworkTileProvider(),
                    ),
                    MarkerLayerOptions(markers: userLocationMarkers),
                    UserLocationOptions(
                      markers: userLocationMarkers,
                      onLocationUpdate: (LatLng loc) {
                        print('Location updated: $loc');
                      },
                      onLocationRequested: (LatLng loc) {
                        if (loc == null) {
                          return;
                        }
                        mapController?.move(loc, 16.0);
                      },
                      buttonBuilder: (BuildContext context,
                          ValueNotifier<UserLocationServiceStatus> status,
                          Function onPressed) {
                        return Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                bottom: 16.0, right: 16.0),
                            child: FloatingActionButton(
                                child: ValueListenableBuilder<
                                        UserLocationServiceStatus>(
                                    valueListenable: status,
                                    builder: (BuildContext context,
                                        UserLocationServiceStatus value,
                                        Widget child) {
                                      switch (value) {
                                        case UserLocationServiceStatus.disabled:
                                        case UserLocationServiceStatus
                                            .permissionDenied:
                                        case UserLocationServiceStatus
                                            .unsubscribed:
                                          return const Icon(
                                            Icons.location_disabled,
                                            color: Colors.white,
                                          );
                                          break;
                                        default:
                                          return const Icon(
                                            Icons.location_searching,
                                            color: Colors.white,
                                          );
                                          break;
                                      }
                                    }),
                                onPressed: () => onPressed()),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
