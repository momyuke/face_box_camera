import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:face_box_camera/face_box_camera.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FaceBoxController faceBoxController = FaceBoxController(
    cameraLensDirection: CameraLensDirection.back,
    options: FaceBoxOptions(
      minOverlapPercent: 0.5,
      requireCenterInside: true,
      throttleDuration: Duration(milliseconds: 0),
    ),
  );

  bool _isFaceInsideBox = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: FaceBoxCameraWidget(
                controller: faceBoxController,
                onFaceInsideBox: (face, overlap) {
                  log('Face inside box is called');
                  log("Overlap percent: $overlap");
                  setState(() {
                    _isFaceInsideBox = true;
                  });
                },
                onFaceOutsideBox: () {
                  log('Face outside box is called');
                  setState(() {
                    _isFaceInsideBox = false;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  if (_isFaceInsideBox)
                    const Text(
                      'Face is inside the box',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    )
                  else
                    const Text(
                      'Face is outside the box',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        faceBoxController.switchLense();
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.shade100,
                          shape: BoxShape.circle,
                        ),
                        width: 100,
                        height: 100,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
