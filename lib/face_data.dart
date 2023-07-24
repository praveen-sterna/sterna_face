import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceData {
  CameraImage? centerAngleInputImage;
  CameraImage? leftAngleInputImage;
  Face? centerFace;
  CameraImage? rightAngleInputImage;

  FaceData({this.centerAngleInputImage,this.leftAngleInputImage,this.rightAngleInputImage,this.centerFace});
}


enum FaceAngle{
  left,
  right,
  center,
  none
}