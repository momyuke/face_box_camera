import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// A small helper that converts CameraImage -> InputImage and runs the ML Kit face detector.
/// This preserves the original behavior (returns first detected Face or null).
///
/// Note: keep the FaceDetector as a long-lived field and call dispose() when done.
class MlkitHelper {
  final List<CameraDescription> cameras;
  final CameraController cameraController;

  MlkitHelper({required this.cameras, required this.cameraController});

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableClassification: true,
      enableTracking: true,
    ),
  );

  // map DeviceOrientation -> degrees used by Android rotation compensation
  static const Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  /// Process a single camera image and return the first detected face (or null).
  Future<Face?> processCameraImage(CameraImage image) async {
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return null;
      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty) return null;
      return faces[0];
    } catch (e) {
      // don't crash the stream — return null on error
      return null;
    }
  }

  /// Scaling Rct from camera to preview camera size
  Rect scaleRectPreviewToScreen(
    Rect faceBox,
    Size previewSize,
    Size screenSize,
  ) {
    double scaleX = screenSize.width / previewSize.height;
    double scaleY = screenSize.height / previewSize.width;

    return Rect.fromLTRB(
      faceBox.left * scaleX,
      faceBox.top * scaleY,
      faceBox.right * scaleX,
      faceBox.bottom * scaleY,
    );
  }

  /// Convert CameraImage to InputImage. Returns null when conversion not possible.
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // pick the camera that corresponds to the controller (fallback to first camera)
    final camera = cameras.isNotEmpty ? cameras[0] : null;
    if (camera == null) return null;
    final sensorOrientation = camera.sensorOrientation;

    // rotation compensation (Android needs special handling)
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      final deviceOrientation = cameraController.value.deviceOrientation;
      final rotationCompensation = _orientations[deviceOrientation];
      if (rotationCompensation == null) return null;

      int rotationDegrees;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front camera: add compensation then normalize
        rotationDegrees = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back camera
        rotationDegrees =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationDegrees);
    }
    if (rotation == null) return null;

    // determine input format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    // support nv21 and yuv_420_888 on Android, bgra8888 on iOS
    if (Platform.isAndroid &&
        format != InputImageFormat.nv21 &&
        format != InputImageFormat.yuv_420_888) {
      return null;
    }
    if (Platform.isIOS && format != InputImageFormat.bgra8888) {
      return null;
    }

    // Compose bytes (convert YUV420 -> NV21 if needed)
    late final Uint8List bytes;
    if (format == InputImageFormat.yuv_420_888) {
      bytes = _convertYUV420ToNV21(image);
    } else {
      // for nv21 or bgra8888, simply take first plane's bytes (plugin conventions)
      bytes = image.planes.first.bytes;
    }

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        // format to indicate the expected platform representation
        format: Platform.isAndroid
            ? InputImageFormat.nv21
            : InputImageFormat.bgra8888,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  /// Convert YUV_420_888 -> NV21 (YYYY VU interleaved) in a robust way that takes row/pixel strides into account.
  Uint8List _convertYUV420ToNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final planeY = image.planes[0];
    final planeU = image.planes[1];
    final planeV = image.planes[2];

    final yRowStride = planeY.bytesPerRow;
    final yPixelStride = planeY.bytesPerPixel ?? 1;

    final uRowStride = planeU.bytesPerRow;
    final uPixelStride = planeU.bytesPerPixel ?? 1;

    final vRowStride = planeV.bytesPerRow;
    final vPixelStride = planeV.bytesPerPixel ?? 1;

    final int frameSize = width * height;
    final int chromaSize = frameSize ~/ 2;
    final nv21 = Uint8List(frameSize + chromaSize);

    int pos = 0;

    // Copy Y plane (full resolution)
    for (int row = 0; row < height; row++) {
      final int yRowStart = row * yRowStride;
      for (int col = 0; col < width; col++) {
        nv21[pos++] = planeY.bytes[yRowStart + col * yPixelStride];
      }
    }

    // NV21 requires V and U interleaved for each 2x2 block: V U V U ...
    // Chroma has half resolution in both directions
    final int chromaHeight = (height / 2).floor();
    final int chromaWidth = (width / 2).floor();

    for (int row = 0; row < chromaHeight; row++) {
      final int uRowStart = row * uRowStride;
      final int vRowStart = row * vRowStride;
      for (int col = 0; col < chromaWidth; col++) {
        final int uIndex = uRowStart + col * uPixelStride;
        final int vIndex = vRowStart + col * vPixelStride;

        // V first then U (NV21 = Y V U)
        nv21[pos++] = planeV.bytes[vIndex];
        nv21[pos++] = planeU.bytes[uIndex];
      }
    }

    return nv21;
  }

  /// Close detector
  void dispose() {
    _faceDetector.close();
  }
}
