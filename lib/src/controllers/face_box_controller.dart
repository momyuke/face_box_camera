import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:face_box_camera/src/models/eye_blink_buffer.dart';
import 'package:face_box_camera/src/models/face_box_camera_mode.dart';
import 'package:flutter/material.dart';

import '../models/face_box_options.dart';
import '../models/face_info.dart';
import '../services/detection_helper.dart';
import '../services/mlkit_helper.dart';

typedef FaceDetectedCallback = void Function(FaceInfo face);
typedef FaceInsideBoxCallback = void Function(FaceInfo face, double overlap);
typedef FaceErrorCallback = void Function(Object error);

class FaceBoxController {
  final FaceBoxOptions options;

  /// Decide which camera direction that would be use
  final CameraLensDirection? cameraLensDirection;

  /// Called whenever a face is detected (first face only for now).
  final FaceDetectedCallback? onFaceDetected;

  /// Called when a detected face is inside the defined box.
  final FaceInsideBoxCallback? onFaceInsideBox;

  /// Called when a detected face is inside the defined box.
  final VoidCallback? onEyeBlink;

  /// Called on error.
  FaceErrorCallback? onError;

  CameraController? _cameraController;
  late MlkitHelper _mlkitHelper;

  /// Buffer frames to decide is eye blink or not
  final EyeBlinkBuffer _eyeBlinkBuffer = EyeBlinkBuffer();

  /// List of available cameras
  List<CameraDescription> _cameras = [];

  bool _running = false;
  Timer? _throttleTimer;

  bool isProcessingFrame = false;

  /// Latest detected faces (ValueNotifier for listening in widgets).
  final ValueNotifier<List<FaceInfo>> facesNotifier =
      ValueNotifier<List<FaceInfo>>([]);

  /// Camera Controller
  CameraController? get cameraController => _cameraController;

  FaceBoxController({
    required this.options,
    this.onFaceDetected,
    this.onError,
    this.onFaceInsideBox,
    this.cameraLensDirection,
    this.onEyeBlink,
  });

  FaceBoxController copyWith({
    FaceBoxOptions? options,
    FaceErrorCallback? onError,
    FaceDetectedCallback? onFaceDetected,
    FaceInsideBoxCallback? onFaceInsideBox,
    CameraLensDirection? cameraLensDirection,
    VoidCallback? onEyeBlink,
  }) {
    return FaceBoxController(
      options: options ?? this.options,
      onError: onError ?? this.onError,
      onFaceDetected: onFaceDetected ?? this.onFaceDetected,
      onFaceInsideBox: onFaceInsideBox ?? this.onFaceInsideBox,
      cameraLensDirection: cameraLensDirection ?? this.cameraLensDirection,
      onEyeBlink: onEyeBlink ?? this.onEyeBlink,
    );
  }

  Future<void> _initializeCamera(CameraDescription camera) async {
    try {
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,

        /// According to ML Kit docs, the accepted ImageFormatGroup for Android only nv21 and iOS only bgra8888
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
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
      CameraDescription selectedCamera = _cameras.first;
      if (cameraLensDirection != null) {
        selectedCamera = _cameras.firstWhere(
          (camera) => camera.lensDirection == cameraLensDirection,
        );
      }
      await _initializeCamera(selectedCamera);
    } catch (e) {
      onError?.call(e);
    }
  }

  void _startImageStream() {
    _cameraController?.startImageStream((CameraImage image) async {
      if (isProcessingFrame &&
          options.faceBoxCameraMode == FaceBoxCameraMode.block) {
        return;
      }
      isProcessingFrame = true;

      // throttle to ~10 FPS
      if (_throttleTimer?.isActive ?? false) return;
      _throttleTimer = Timer(options.throttleDuration, () {});

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

      _eyeBlinkBuffer.add(
        face.leftEyeOpenProbability ?? 0,
        face.rightEyeOpenProbability ?? 0,
      );

      if (_eyeBlinkBuffer.isBlinking()) {
        onEyeBlink?.call();
        _eyeBlinkBuffer.clear();
      }

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

      isProcessingFrame = false;
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
