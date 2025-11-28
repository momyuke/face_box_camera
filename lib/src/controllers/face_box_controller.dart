// ignore_for_file: use_build_context_synchronously

import 'dart:async';
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

  VoidCallback? onFaceOutsideBox;

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

  // FPS measurement
  int _processedFrames = 0;
  Timer? _fpsTimer;
  final ValueNotifier<double> fpsNotifier = ValueNotifier<double>(0.0);

  /// Last frame processing time in milliseconds (time spent in to all processing in image stream)
  final ValueNotifier<double> processingTimeNotifier = ValueNotifier<double>(
    0.0,
  );

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

        /// Max FPS that we can used is 30 FPS since Flutter camera plugin only support up to 30 FPS
        /// even we can set higher than 30 the streaming image would only support up to 30 FPS
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

      // Start FPS timer: publish number of processed frames per second
      _fpsTimer?.cancel();
      _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        fpsNotifier.value = _processedFrames.toDouble();
        _processedFrames = 0;
      });
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

      final sw = Stopwatch()..start();
      isProcessingFrame = true;
      try {
        // throttle to ~10 FPS
        if (_throttleTimer?.isActive ?? false) {
          return;
        }
        if (options.throttleDuration > Duration.zero) {
          _throttleTimer = Timer(options.throttleDuration, () {});
        }

        // Measure processing time for this frame
        final face = await _mlkitHelper.processCameraImage(image);

        // Count processed frames for FPS measurement (frames sent to ML processing)
        _processedFrames++;
        if (face == null) {
          facesNotifier.value = [];
          return;
        }
        // Use the preview widget size & offset to map camera coords into the
        // global coordinate space (same space used by options.boxLimitRect).
        final previewContext = options.previewKey?.currentContext;
        if (previewContext == null) return;
        final previewSize = previewContext.size;
        if (previewSize == null) return;

        // Map face bounding box (camera image coords) -> preview widget coords
        final mappedInPreview = _mlkitHelper.scaleRectPreviewToScreen(
          face.boundingBox,
          _cameraController!.value.previewSize!,
          previewSize,
        );

        // Convert mapped rect (preview-local) to global coordinates by adding
        // the preview widget's global offset so it can be compared with
        // options.boxLimitRect (which uses localToGlobal when reporting rect).
        final previewBox = previewContext.findRenderObject() as RenderBox;
        final previewOffset = previewBox.localToGlobal(Offset.zero);
        final rect = mappedInPreview.shift(previewOffset);

        // check inside-box
        final dh = DetectionHelper(
          limitBoxCoordinate: options.boxLimitRect,
          detectionFaceCoordinate: rect,
        );

        final isInside = dh.isInside(
          isRequiredCenter: options.requireCenterInside,
          minOverlapPercent: options.minOverlapPercent,
        );

        _eyeBlinkBuffer.addFrame(
          face.leftEyeOpenProbability ?? 0,
          face.rightEyeOpenProbability ?? 0,
        );

        final faceInfo = FaceInfo(
          boundingBox: rect,
          trackingId: face.trackingId?.toDouble(),
          smilingProbability: face.smilingProbability,
        );

        facesNotifier.value = [faceInfo];
        onFaceDetected?.call(faceInfo);

        if (isInside) {
          onFaceInsideBox?.call(face, dh.overlapPercent());
        } else {
          onFaceOutsideBox?.call();
        }
      } catch (e) {
        onError?.call(e);
      } finally {
        isProcessingFrame = false;
        sw.stop();
        processingTimeNotifier.value = sw.elapsedMilliseconds.toDouble();
      }
    });
  }

  /// Disposing the FaceBoxCamera
  Future<void> dispose() async {
    _throttleTimer?.cancel();
    await _cameraController?.dispose();
    _mlkitHelper.dispose();
    facesNotifier.dispose();
    _fpsTimer?.cancel();
    fpsNotifier.dispose();
    processingTimeNotifier.dispose();
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
      onError?.call(e);
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
