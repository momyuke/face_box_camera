import 'dart:async';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../models/face_info.dart';
import '../models/face_box_options.dart';
import '../services/mlkit_helper.dart';
import '../services/detection_helper.dart';

typedef FaceDetectedCallback = void Function(FaceInfo face);
typedef FaceInsideBoxCallback = void Function(FaceInfo face, double overlap);

class FaceBoxController {
  final FaceBoxOptions options;

  /// Called whenever a face is detected (first face only for now).
  FaceDetectedCallback? onFaceDetected;

  /// Called when a detected face is inside the defined box.
  FaceInsideBoxCallback? onFaceInsideBox;

  /// Called on error.
  void Function(Object error)? onError;

  late CameraController _cameraController;
  late MlkitHelper _mlkitHelper;
  List<CameraDescription> _cameras = [];

  bool _running = false;
  Timer? _throttleTimer;

  void testMantap(){

  }

  /// Latest detected faces (ValueNotifier for listening in widgets).
  final ValueNotifier<List<FaceInfo>> facesNotifier =
      ValueNotifier<List<FaceInfo>>([]);
      
  FaceBoxController({required this.options});

  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception("No cameras available");

      _cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController.initialize();

      _mlkitHelper =
          MlkitHelper(cameras: _cameras, cameraController: _cameraController);

      _running = true;
      _startImageStream();
    } catch (e) {
      onError?.call(e);
    }
  }

  void _startImageStream() {
    _cameraController.startImageStream((CameraImage image) async {
      // throttle to ~10 FPS
      if (_throttleTimer?.isActive ?? false) return;
      _throttleTimer = Timer(const Duration(milliseconds: 100), () {});

      final face = await _mlkitHelper.processCameraImage(image);
      if (face == null) {
        facesNotifier.value = [];
        return;
      }

      final rect = Rect.fromLTWH(
        face.boundingBox.left / image.width,
        face.boundingBox.top / image.height,
        face.boundingBox.width / image.width,
        face.boundingBox.height / image.height,
      );

      final faceInfo = FaceInfo(
        boundingBox: rect,
        trackingId: face.trackingId?.toDouble(),
        smilingProbability: face.smilingProbability,
      );

      facesNotifier.value = [faceInfo];
      if(onFaceDetected != null){
        onFaceDetected!(faceInfo);
      }

      // check inside-box
      final dh = DetectionHelper(
        limitBoxCoordinate: options.boxRect,
        detectionFaceCoordinate: rect,
      );

      final overlap = dh.overlapPercent();
      final inside = options.requireCenterInside
          ? dh.centerInside()
          : overlap >= options.minOverlapPercent;

      if (inside && onFaceInsideBox != null) {
        onFaceInsideBox!(faceInfo, overlap);
      }
    });
  }

  CameraController get cameraController => _cameraController;

  Future<void> dispose() async {
    _running = false;
    _throttleTimer?.cancel();
    await _cameraController.dispose();
    _mlkitHelper.dispose();
    facesNotifier.dispose();
  }
}
