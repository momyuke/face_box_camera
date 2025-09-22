import 'package:flutter/material.dart';

/// Options to configure the "target box" region where a face should appear.
class FaceBoxOptions {
  /// Used to decided the size of the limit box
  GlobalKey? boxKey;

  /// Return either Rect from key.
  /// Will return [Rect.zero] if both is null
  Rect get boxLimitRect {
    if (boxKey != null) {
      final box = boxKey?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return Rect.zero;
      final size = box.size;
      final offset = box.localToGlobal(Offset.zero);
      return offset & size;
    }
    return Rect.zero;
  }

  /// Require center of face in box (true) or use overlapPercent (false).
  final bool requireCenterInside;

  /// Minimum overlap percent [0..1] if [requireCenterInside] is false.
  final double minOverlapPercent;

  FaceBoxOptions({
    this.requireCenterInside = true,
    this.minOverlapPercent = 0.5,
    this.boxKey,
  });
}
