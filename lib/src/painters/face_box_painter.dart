import 'package:flutter/material.dart';

class FaceBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Define scaling factors based on original design size (316 x 379)
    final double xScale = size.width / 316;
    final double yScale = size.height / 379;

    Path path_0 = Path();
    path_0.moveTo(158 * xScale, 2 * yScale);
    path_0.cubicTo(
      244.156 * xScale,
      2 * yScale,
      314 * xScale,
      71.8436 * yScale,
      314 * xScale,
      158 * yScale,
    );
    path_0.cubicTo(
      314 * xScale,
      201.178 * yScale,
      296.466 * xScale,
      255.931 * yScale,
      268.043 * xScale,
      299.887 * yScale,
    );
    path_0.cubicTo(
      239.572 * xScale,
      343.917 * yScale,
      200.596 * xScale,
      376.5 * yScale,
      158 * xScale,
      376.5 * yScale,
    );
    path_0.cubicTo(
      115.404 * xScale,
      376.5 * yScale,
      76.4285 * xScale,
      343.917 * yScale,
      47.957 * xScale,
      299.887 * yScale,
    );
    path_0.cubicTo(
      19.534 * xScale,
      255.931 * yScale,
      2 * xScale,
      201.178 * yScale,
      2 * xScale,
      158 * yScale,
    );
    path_0.cubicTo(
      2 * xScale,
      71.8436 * yScale,
      71.8436 * xScale,
      2 * yScale,
      158 * xScale,
      2 * yScale,
    );
    path_0.close();

    Paint paint0Stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.01265823
      ..color = Colors.white.withValues(alpha: 1.0);
    canvas.drawPath(path_0, paint0Stroke);

    Paint paint0Fill = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xff000000).withValues(alpha: 0);
    canvas.drawPath(path_0, paint0Fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
