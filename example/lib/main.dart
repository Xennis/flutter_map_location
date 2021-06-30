import 'package:flutter/material.dart';

import 'pages/controller.dart';
import 'pages/custom.dart';
import 'pages/default.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Location Examples',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: DefaultPage(),
        routes: <String, WidgetBuilder>{
          CustomPage.route: (_) => CustomPage(),
          ControllerPage.route: (_) => ControllerPage(),
        });
  }
}
