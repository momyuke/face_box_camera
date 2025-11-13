import 'package:camera/camera.dart';
import 'package:face_box_camera/src/domains/domains.dart';
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

  /// Called whenever there eye blink
  final VoidCallback? onEyeBlink;

  /// Child that would be a limitor for detection face. Either the face is inside the child or not
  final Widget? child;

  /// Called when camera is being initialized
  final Widget? onLoadingWidget;

  const FaceBoxCameraWidget({
    super.key,
    required this.controller,
    this.child,
    this.onLoadingWidget,
    this.onFaceDetected,
    this.onFaceInsideBox,
    this.onError,
    this.onEyeBlink,
  });

  @override
  State<FaceBoxCameraWidget> createState() => _FaceBoxCameraWidgetState();
}

class _FaceBoxCameraWidgetState extends State<FaceBoxCameraWidget> {
  final GlobalKey _boxLimitKey = GlobalKey();
  // Key attached to CameraPreview so controller can map camera coords -> global coords
  final GlobalKey _previewKey = GlobalKey();

  @override
  void initState() {
    widget.controller.onError = widget.onError;
    widget.controller.onFaceDetected = widget.onFaceDetected;
    widget.controller.onEyeBlink = widget.onEyeBlink;
    widget.controller.onFaceInsideBox = widget.onFaceInsideBox;
    widget.controller.options.boxKey = _boxLimitKey;
    widget.controller.options.previewKey = _previewKey;
    widget.controller.initialize();
    super.initState();
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.controller.facesNotifier,
      builder: (_, faces, __) {
        if (!(widget.controller.cameraController?.value.isInitialized ??
            false)) {
          return Center(
            child: widget.onLoadingWidget ?? CircularProgressIndicator(),
          );
        }
        return Stack(
          children: [
            Positioned.fill(
              // attach key so we can measure preview widget size & offset
              child: CameraPreview(
                widget.controller.cameraController!,
                key: _previewKey,
              ),
            ),
            if (widget.child != null)
              Center(
                child: SizedBox(key: _boxLimitKey, child: widget.child),
              ),

            if (widget.child == null)
              Center(
                child: CustomPaint(
                  key: _boxLimitKey,
                  size: Size(316, 379),
                  painter: FaceBoxPainter(),
                ),
              ),
          ],
        );
      },
    );
  }
}
