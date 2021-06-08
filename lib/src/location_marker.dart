import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map_location/src/types.dart';

double _degree2Radian(double degree) {
  return degree * pi / 180.0;
}

class LocationMarker extends StatelessWidget {
  const LocationMarker(this.ld, this.heading, {Key? key}) : super(key: key);

  static final CustomPainter headingerPainter = LocationMarkerHeading();
  final LatLngData ld;
  final ValueNotifier<double?> heading;

  @override
  Widget build(BuildContext context) {
    final double diameter = ld.highAccuracy() ? 22.0 : 80.0;
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Stack(
            alignment: AlignmentDirectional.center,
            children: <Widget>[
              ValueListenableBuilder<double?>(
                  valueListenable: heading,
                  builder:
                      (BuildContext context, double? value, Widget? child) {
                    if (value == null) {
                      return Container();
                    }
                    // Only display heading for an accurate location.
                    if (!ld.highAccuracy()) {
                      return Container();
                    }
                    return Transform.rotate(
                      angle: _degree2Radian(value),
                      child: CustomPaint(
                        painter: headingerPainter,
                      ),
                    );
                  }),
              Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue[300]!.withOpacity(0.7)),
                height: diameter,
                width: diameter,
              ),
              Container(
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.blueAccent),
                height: 14.0,
                width: 14.0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LocationMarkerHeading extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromCircle(
      center: Offset.zero,
      radius: 50,
    );
    final Gradient gradient = RadialGradient(
      colors: <Color>[
        Colors.blue.shade500.withOpacity(0.7),
        Colors.blue.shade500.withOpacity(0.3),
        Colors.transparent,
      ],
      stops: const <double>[
        0.0,
        0.5,
        1.0,
      ],
    );
    final Paint paint = Paint();
    paint.shader = gradient.createShader(rect);
    canvas.drawArc(rect, _degree2Radian(200), _degree2Radian(140), true, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
