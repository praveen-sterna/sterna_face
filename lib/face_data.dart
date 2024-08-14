
import 'dart:typed_data';

import 'package:camera/camera.dart';

class FaceData {
  Uint8List? centerAngleInputImage;
  Uint8List? leftAngleInputImage;
  Uint8List? rightAngleInputImage;

  FaceData({this.centerAngleInputImage,this.leftAngleInputImage,this.rightAngleInputImage});
}


enum FaceAngle{
  left,
  right,
  center,
  none
}