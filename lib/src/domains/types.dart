import 'package:face_box_camera/src/domains/models/face_info.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

typedef FaceDetectedCallback = void Function(FaceInfo face);
typedef FaceInsideBoxCallback = void Function(Face face, double overlap);
typedef FaceErrorCallback = void Function(Object error);
