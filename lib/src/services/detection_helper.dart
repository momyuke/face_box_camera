// lib/src/services/detection_helper.dart
import 'dart:ui';

/// Utility to decide whether a detected face rect is "inside" a limit box.
/// - `requireCenterInside`: true -> check face.center in limitBox
/// - otherwise check overlapPercent >= minOverlap
class DetectionHelper {
  final Rect limitBoxCoordinate;
  final Rect detectionFaceCoordinate;

  const DetectionHelper({
    required this.limitBoxCoordinate,
    required this.detectionFaceCoordinate,
  });

  /// Original strict check (both corners inside)
  bool strictCornersInside() {
    return limitBoxCoordinate.contains(detectionFaceCoordinate.topLeft) &&
        limitBoxCoordinate.contains(detectionFaceCoordinate.bottomRight);
  }

  /// Check center-in-box
  bool centerInside() {
    return limitBoxCoordinate.contains(detectionFaceCoordinate.center);
  }


  /// Compute overlap percent relative to face area (0..1)
  double overlapPercent() {
    final intersection = detectionFaceCoordinate.intersect(limitBoxCoordinate);
    if (intersection.isEmpty) return 0.0;
    final double interArea = intersection.width * intersection.height;
    final double faceArea =
        detectionFaceCoordinate.width * detectionFaceCoordinate.height;
    if (faceArea <= 0) return 0.0;
    return interArea / faceArea;
  }

  /// Convenience: whichever strategy you want. By default use centerInside.
  bool isFaceInsideBox({double minOverlap = 0.5, bool requireCenter = true}) {
    if (requireCenter) return centerInside();
    return overlapPercent() >= minOverlap;
  }
}
