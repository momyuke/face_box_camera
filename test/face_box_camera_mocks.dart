import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:face_box_camera/src/controllers/face_box_controller.dart';

class FaceBoxCameraMocks extends FaceBoxController {
  FaceBoxCameraMocks({required super.options, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  Future<List<CameraDescription>> getAvailableCameras() async {
    return cameras;
  }

  @override
  Future<void> initializedCamera() async {
    return;
  }

  @override
  Future<void> dispose() async {
    cameras.clear();
    super.dispose();
  }
}
