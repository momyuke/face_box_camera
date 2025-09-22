import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../controllers/face_box_controller.dart';
import '../painters/face_box_painter.dart';

class FaceBoxCameraWidget extends StatefulWidget {
  final FaceBoxController controller;

  /// Child that would be a limitor for detection face. Either the face is inside the child or not
  final Widget? child;

  const FaceBoxCameraWidget({super.key, required this.controller, this.child});

  @override
  State<FaceBoxCameraWidget> createState() => _FaceBoxCameraWidgetState();
}

class _FaceBoxCameraWidgetState extends State<FaceBoxCameraWidget> {
  final GlobalKey _boxLimitKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    widget.controller.options.boxKey = _boxLimitKey;
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
            if (widget.child != null)
              SizedBox(key: _boxLimitKey, child: widget.child),

            if (widget.child == null)
              CustomPaint(
                key: _boxLimitKey,
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
