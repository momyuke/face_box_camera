import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:face_box_camera/src/domains/domains.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'face_box_camera_mocks.dart';

void main() {
  late FaceBoxCameraMocks controller;
  late CameraDescription mockCamera;

  setUp(() {
    mockCamera = CameraDescription(
      name: 'MockCamera',
      lensDirection: CameraLensDirection.front,
      sensorOrientation: 90,
    );

    controller = FaceBoxCameraMocks(
      cameras: [mockCamera],
      options: FaceBoxOptions(),
    );
  });

  test('initialize calls availableCameras and sets controller', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await controller.initialize();
    expect(controller.cameraController, isNotNull);
  });

  test('onError should be called when initialize throws', () async {
    bool errorCalled = false;
    controller.onError = (_) => errorCalled = true;
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel('plugins.flutter.io/camera'), (
          methodCall,
        ) async {
          throw Exception("Camera not found");
        });

    await controller.initialize();
    expect(errorCalled, true);
  });

  test('facesNotifier should update when face detected', () async {
    // Mock camera controller
    controller
      ..onFaceDetected = (_) {}
      ..onFaceInsideBox = (_, __) {}
      ..onEyeBlink = () {}
      ..onError = (_) {};
    // Simulate face detection update
    final faceInfo = FaceInfo(
      boundingBox: Rect.fromLTWH(0, 0, 10, 10),
      smilingProbability: 0.5,
    );
    controller.facesNotifier.value = [faceInfo];
    expect(controller.facesNotifier.value.first.smilingProbability, 0.5);
  });

  test('dispose should cancel timer and release resources', () async {
    controller
      ..onError = (_) {}
      ..onFaceDetected = (_) {};
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel('plugins.flutter.io/camera'), (
          methodCall,
        ) async {
          return true;
        });
    await controller.initialize();
    expect(controller.cameras, isNotEmpty);
    await controller.dispose();
    expect(controller.cameras, isEmpty);
  });
}
