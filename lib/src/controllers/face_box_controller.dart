import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/face_box_options.dart';
import '../models/face_info.dart';
import '../services/detection_helper.dart';
import '../services/mlkit_helper.dart';

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

  CameraController? _cameraController;
  late MlkitHelper _mlkitHelper;

  /// List of available cameras
  List<CameraDescription> _cameras = [];

  bool _running = false;
  Timer? _throttleTimer;

  /// Latest detected faces (ValueNotifier for listening in widgets).
  final ValueNotifier<List<FaceInfo>> facesNotifier =
      ValueNotifier<List<FaceInfo>>([]);

  /// Camera Controller
  CameraController? get cameraController => _cameraController;

  FaceBoxController({required this.options});

  Future<void> _initializeCamera(CameraDescription camera) async {
    try {
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController?.initialize();

      _mlkitHelper = MlkitHelper(
        cameras: _cameras,
        cameraController: _cameraController!,
      );

      _running = true;
      _startImageStream();
    } catch (e) {
      onError?.call(e);
    }
  }

  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception("No cameras available");
      await _initializeCamera(_cameras.first);
    } catch (e) {
      onError?.call(e);
    }
  }

  void _startImageStream() {
    _cameraController?.startImageStream((CameraImage image) async {
      // throttle to ~10 FPS
      if (_throttleTimer?.isActive ?? false) return;
      _throttleTimer = Timer(const Duration(milliseconds: 100), () {});

      final face = await _mlkitHelper.processCameraImage(image);
      if (face == null) {
        facesNotifier.value = [];
        return;
      }
      final contextSize = options.boxKey?.currentContext?.size;
      if (contextSize == null) return;
      final rect = _mlkitHelper.scaleRectPreviewToScreen(
        face.boundingBox,
        _cameraController!.value.previewSize!,
        contextSize,
      );

      final faceInfo = FaceInfo(
        boundingBox: rect,
        trackingId: face.trackingId?.toDouble(),
        smilingProbability: face.smilingProbability,
      );

      facesNotifier.value = [faceInfo];
      if (onFaceDetected != null) {
        onFaceDetected!(faceInfo);
      }

      // check inside-box
      final dh = DetectionHelper(
        limitBoxCoordinate: options.boxLimitRect,
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

  Future<void> dispose() async {
    _running = false;
    _throttleTimer?.cancel();
    await _cameraController?.dispose();
    _mlkitHelper.dispose();
    facesNotifier.dispose();
  }

  Future<void> switchLense() async {
    final newCamera = _cameras.firstWhere(
      (camera) =>
          camera.lensDirection != _cameraController?.description.lensDirection,
    );
    await dispose();
    _initializeCamera(newCamera);
  }
}
