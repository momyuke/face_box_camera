import 'package:flutter/material.dart';

import '../models/face_info.dart';
import '../models/face_box_options.dart';

class FaceBoxPainter extends CustomPainter {
  final FaceBoxOptions options;
  final List<FaceInfo> faces;

  FaceBoxPainter({
    required this.options,
    required this.faces,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.red;

    final facePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.green;

    // Draw the target box
    final targetRect = Rect.fromLTWH(
      options.boxRect.left * size.width,
      options.boxRect.top * size.height,
      options.boxRect.width * size.width,
      options.boxRect.height * size.height,
    );
    canvas.drawRect(targetRect, boxPaint);

    // Draw faces
    for (final f in faces) {
      final faceRect = Rect.fromLTWH(
        f.boundingBox.left * size.width,
        f.boundingBox.top * size.height,
        f.boundingBox.width * size.width,
        f.boundingBox.height * size.height,
      );
      canvas.drawRect(faceRect, facePaint);
    }
  }

  @override
  bool shouldRepaint(covariant FaceBoxPainter old) {
    return old.faces != faces || old.options != options;
  }
}
