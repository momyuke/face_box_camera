import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../controllers/face_box_controller.dart';
import '../painters/face_box_painter.dart';

class FaceBoxCameraWidget extends StatefulWidget {
  final FaceBoxController controller;

  /// Called whenever face detected (whether the face inside a box or not)
  final FaceDetectedCallback? onFaceDetected;

  /// Called whenever face detected inside box
  final FaceInsideBoxCallback? onFaceInsideBox;

  /// Called whenever there is an error inside logic FaceBoxCamera package
  final FaceErrorCallback? onError;

  /// Child that would be a limitor for detection face. Either the face is inside the child or not
  final Widget? child;
  final Widget? onLoadingWidget;

  const FaceBoxCameraWidget({
    super.key,
    required this.controller,
    this.child,
    this.onLoadingWidget,
    this.onFaceDetected,
    this.onFaceInsideBox,
    this.onError,
  });

  @override
  State<FaceBoxCameraWidget> createState() => _FaceBoxCameraWidgetState();
}

class _FaceBoxCameraWidgetState extends State<FaceBoxCameraWidget> {
  final GlobalKey _boxLimitKey = GlobalKey();
  late FaceBoxController _controller;

  @override
  void initState() {
    _controller = widget.controller.copyWith(
      onError: widget.onError,
      onFaceDetected: widget.onFaceDetected,
      onFaceInsideBox: widget.onFaceInsideBox,
    );
    _controller.initialize();
    _controller.options.boxKey = _boxLimitKey;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _controller.facesNotifier,
      builder: (_, faces, __) {
        if (!(_controller.cameraController?.value.isInitialized ?? false)) {
          return Center(
            child: widget.onLoadingWidget ?? CircularProgressIndicator(),
          );
        }
        return Stack(
          children: [
            Positioned.fill(
              child: CameraPreview(_controller.cameraController!),
            ),
            if (widget.child != null)
              Center(
                child: SizedBox(key: _boxLimitKey, child: widget.child),
              ),

            if (widget.child == null)
              CustomPaint(
                key: _boxLimitKey,
                painter: FaceBoxPainter(
                  options: _controller.options,
                  faces: faces,
                ),
              ),
          ],
        );
      },
    );
  }
}
