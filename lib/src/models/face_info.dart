import 'dart:ui';

/// Represents a detected face in normalized coordinates (0..1).
class FaceInfo {
  final Rect boundingBox; // normalized bounding box
  final double? trackingId;
  final double? smilingProbability;

  const FaceInfo({
    required this.boundingBox,
    this.trackingId,
    this.smilingProbability,
  });
}