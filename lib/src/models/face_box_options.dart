import 'dart:ui';

/// Options to configure the "target box" region where a face should appear.
class FaceBoxOptions {
  /// Normalized rect (0..1) relative to camera preview.
  final Rect boxRect;

  /// Require center of face in box (true) or use overlapPercent (false).
  final bool requireCenterInside;

  /// Minimum overlap percent [0..1] if [requireCenterInside] is false.
  final double minOverlapPercent;

  const FaceBoxOptions({
    required this.boxRect,
    this.requireCenterInside = true,
    this.minOverlapPercent = 0.5,
  });
}