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
      minOverlapPercent: 0.2,
      requireCenterInside: false,
      throttleDuration: Duration(milliseconds: 0),
    ),
  );

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
      // home: Myapp(title: 'Flutter Demo Home Page', cameras: _cameras),
      home: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: FaceBoxCameraWidget(
                controller: faceBoxController,
                onFaceInsideBox: (face, overlap) {
                  log(
                    "Left Prob => ${face.leftEyeOpenProbability} === Right Prob => ${face.rightEyeOpenProbability}",
                  );
                },
                onEyeBlink: () {
                  log("Blinked Eye");
                },
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
