import 'package:camera/camera.dart';

class FaceData {
  CameraImage? centerAngleInputImage;
  CameraImage? leftAngleInputImage;
  CameraImage? rightAngleInputImage;

  FaceData({this.centerAngleInputImage,this.leftAngleInputImage,this.rightAngleInputImage});
}


enum FaceAngle{
  left,
  right,
  center,
  none
}