import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:face_box_camera/src/domains/domains.dart';
import 'package:flutter/material.dart';

import '../services/detection_helper.dart';
import '../services/mlkit_helper.dart';

class FaceBoxController {
  final FaceBoxOptions options;

  /// Decide which camera direction that would be use
  CameraLensDirection? cameraLensDirection;

  /// Called whenever a face is detected (first face only for now).
  FaceDetectedCallback? onFaceDetected;

  /// Called when a detected face is inside the defined box.
  FaceInsideBoxCallback? onFaceInsideBox;

  /// Called when a detected face is inside the defined box.
  VoidCallback? onEyeBlink;

  /// Called on error.
  FaceErrorCallback? onError;

  CameraController? _cameraController;
  late MlkitHelper _mlkitHelper;

  /// Buffer frames to decide is eye blink or not
  final EyeBlinkBuffer _eyeBlinkBuffer = EyeBlinkBuffer();

  /// List of available cameras
  List<CameraDescription> _cameras = [];

  Timer? _throttleTimer;

  bool isProcessingFrame = false;

  /// Latest detected faces (ValueNotifier for listening in widgets).
  final ValueNotifier<List<FaceInfo>> facesNotifier =
      ValueNotifier<List<FaceInfo>>([]);

  /// Camera Controller
  CameraController? get cameraController => _cameraController;
  FaceBoxController({required this.options, this.cameraLensDirection});

  Future<void> _setUp(CameraDescription camera) async {
    try {
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        fps: 30,

        /// According to ML Kit docs, the accepted ImageFormatGroup for Android only nv21 and iOS only bgra8888
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await initializedCamera();

      _mlkitHelper = MlkitHelper(
        cameras: _cameras,
        cameraController: _cameraController!,
      );

      _startImageStream();
    } catch (e) {
      onError?.call(e);
    }
  }

  @visibleForTesting
  Future<void> initializedCamera() async {
    return await _cameraController?.initialize();
  }

  @visibleForTesting
  Future<List<CameraDescription>> getAvailableCameras() {
    return availableCameras();
  }

  /// Initializing the FaceBoxCamera, also
  Future<void> initialize() async {
    try {
      _cameras = await getAvailableCameras();
      if (_cameras.isEmpty) throw Exception("No cameras available");
      CameraDescription selectedCamera = _cameras.first;
      if (cameraLensDirection != null) {
        selectedCamera = _cameras.firstWhere(
          (camera) => camera.lensDirection == cameraLensDirection,
        );
      }
      await _setUp(selectedCamera);
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
      if (options.throttleDuration > Duration.zero) {
        _throttleTimer = Timer(options.throttleDuration, () {});
      }

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

      // check inside-box
      final dh = DetectionHelper(
        limitBoxCoordinate: options.boxLimitRect,
        detectionFaceCoordinate: rect,
      );

      final overlap = dh.overlapPercent();
      final inside = options.requireCenterInside
          ? dh.centerInside()
          : overlap >= options.minOverlapPercent;

      _eyeBlinkBuffer.addFrame(
        face.leftEyeOpenProbability ?? 0,
        face.rightEyeOpenProbability ?? 0,
      );

      if (_eyeBlinkBuffer.isBlinking() && inside) {
        onEyeBlink?.call();
        _eyeBlinkBuffer.clear();
      }

      final faceInfo = FaceInfo(
        boundingBox: rect,
        trackingId: face.trackingId?.toDouble(),
        smilingProbability: face.smilingProbability,
      );

      facesNotifier.value = [faceInfo];
      onFaceDetected?.call(faceInfo);

      if (inside) onFaceInsideBox?.call(face, overlap);
      isProcessingFrame = false;
    });
  }

  /// Disposing the FaceBoxCamera
  Future<void> dispose() async {
    _throttleTimer?.cancel();
    await _cameraController?.dispose();
    _mlkitHelper.dispose();
    facesNotifier.dispose();
    _cameras = [];
    _eyeBlinkBuffer.clear();
  }

  /// Switching lense either front or back
  Future<void> switchLense() async {
    try {
      final newCamera = _cameras.firstWhere(
        (camera) =>
            camera.lensDirection !=
            _cameraController?.description.lensDirection,
        orElse: () => CameraDescription(
          name: '',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 1,
        ),
      );
      if (newCamera.name == '') return;
      _cameraController?.dispose();
      _setUp(newCamera);
    } catch (e) {
      log(e.toString());
    }
  }

  /// Manually stop the camera, it also would be stopping the image start stream
  Future<void> stopCamera() async {
    try {
      _cameraController?.stopImageStream();
      _cameraController?.dispose();
    } catch (e) {
      onError?.call(e);
    }
  }

  /// Manually start the camera
  Future<void> startCamera() async {
    try {
      await initialize();
      _startImageStream();
    } catch (e) {
      onError?.call(e);
    }
  }
}
