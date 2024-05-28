import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomSliderThumb extends SliderComponentShape {
  final double thumbRadius;
  final double sliderValue;

  const CustomSliderThumb({
    required this.thumbRadius,
    required this.sliderValue,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    int sides = 6;
    double innerPolygonRadius = thumbRadius * 1.2;
    double angle = (math.pi * 2) / sides;
    double rectangleWidth = 70;
    double rectangleHeight = 25;
    double wheelRadius = thumbRadius * 0.55;

    // Paint inner path
    final innerPathColor = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.blue
      ..style = PaintingStyle.fill;

    var innerPath = Path();

    Offset startPoint = Offset(
      innerPolygonRadius * math.cos(0.0),
      innerPolygonRadius * math.sin(0.0),
    );

    innerPath.moveTo(
      startPoint.dx + center.dx,
      startPoint.dy + center.dy,
    );

    for (int i = 1; i <= sides; i++) {
      double x = innerPolygonRadius * math.cos(angle * i) + center.dx;
      double y = innerPolygonRadius * math.sin(angle * i) + center.dy;
      innerPath.lineTo(x, y);
    }

    innerPath.close();
    canvas.drawPath(innerPath, innerPathColor);

    // Paint rectangle
    final rectColor = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.blue
      ..style = PaintingStyle.fill;

    RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - rectangleWidth / 2, center.dy - 5,
            rectangleWidth, rectangleHeight),
        const Radius.circular(10));
    canvas.drawRRect(rrect, rectColor);

    // Paint circles
    final circleColor = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    Offset startPointWheel1 = Offset(
      center.dx - rectangleWidth / 5,
      center.dy + rectangleHeight / 2 + 5,
    );

    Offset startPointWheel2 = Offset(
      center.dx - rectangleWidth / 5 + rectangleWidth / 2 - 5,
      center.dy + rectangleHeight / 2 + 5,
    );

    canvas.drawCircle(startPointWheel1, wheelRadius, circleColor);
    canvas.drawCircle(startPointWheel2, wheelRadius, circleColor);

    // Paint text
    TextSpan span = TextSpan(
      style: TextStyle(
        fontSize: thumbRadius - 5,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      text: "${sliderValue.round().toString()} %",
    );

    TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    tp.layout();

    Offset textCenter = Offset(
      center.dx - (tp.width / 2),
      center.dy - (tp.height / 2),
    );

    tp.paint(canvas, textCenter);
  }
}
