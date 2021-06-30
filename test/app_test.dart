import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location/flutter_map_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Render app', (WidgetTester tester) async {
    await tester.pumpWidget(_TestApp());
    // See https://github.com/flutter/flutter/issues/11181#issuecomment-568737491
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(LocationLayer), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  final MapController mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: FlutterMap(
            options: MapOptions(
              plugins: <MapPlugin>[
                LocationPlugin(),
              ],
            ),
            layers: <LayerOptions>[
              TileLayerOptions(
                  urlTemplate: 'https://{s}.tile.example.org/{z}/{x}/{y}.png',
                  subdomains: <String>['a', 'b', 'c']),
              LocationOptions(
                (BuildContext context,
                    ValueNotifier<LocationServiceStatus> status,
                    Function onPressed) {
                  return Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
                      child: FloatingActionButton(
                          child: const Icon(
                            Icons.location_searching,
                          ),
                          onPressed: () {}),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
