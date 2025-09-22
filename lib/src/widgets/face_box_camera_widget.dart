import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../controllers/face_box_controller.dart';
import '../painters/face_box_painter.dart';

class FaceBoxCameraWidget extends StatefulWidget {
  final FaceBoxController controller;
  const FaceBoxCameraWidget({super.key, required this.controller});

  @override
  State<FaceBoxCameraWidget> createState() => _FaceBoxCameraWidgetState();
}

class _FaceBoxCameraWidgetState extends State<FaceBoxCameraWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.initialize();
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ValueListenableBuilder(
      valueListenable: controller.facesNotifier,
      builder: (_, faces, __) {
        if (!controller.cameraController.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller.cameraController),
            CustomPaint(
              painter: FaceBoxPainter(
                options: controller.options,
                faces: faces,
              ),
            ),
          ],
        );
      },
    );
  }
}
