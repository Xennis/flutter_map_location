import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location/flutter_map_location.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../lib/main.dart';

void main() {
  testWidgets('Render app', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(LocationLayer), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
