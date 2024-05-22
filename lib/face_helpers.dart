import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as img_lib;
import 'package:camera/camera.dart';

class FaceHelpers{

  static void showToast(String msg) {
    Fluttertoast.showToast(
        msg: msg,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.grey.shade200,
        textColor: Colors.grey.shade700,
        fontSize: 15);
  }

  static String formatSecondsToMinutes(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    String formattedTime = '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    return formattedTime;
  }

  static Future<Uint8List> _convertBGRA8888ToImage(CameraImage image, CameraLensDirection lensDirection) async {
    final int width = image.width;
    final int height = image.height;
    var img = img_lib.Image(width: width, height: height);
    final bgraBytes = image.planes[0].bytes;
    for (int i = 0; i < width * height; i++) {
      int pixelIndex = i * 4;
      int blue = bgraBytes[pixelIndex];
      int green = bgraBytes[pixelIndex + 1];
      int red = bgraBytes[pixelIndex + 2];
      int alpha = bgraBytes[pixelIndex + 3];
      img.setPixelRgba(i % width, i ~/ width, red, green, blue, alpha);
    }
    img_lib.JpegEncoder jpegEncoder = img_lib.JpegEncoder();
    List<int> jpeg = jpegEncoder.encode(img_lib.copyRotate(img, angle: (lensDirection == CameraLensDirection.front) ? 90 : 0));
    return Uint8List.fromList(jpeg);
  }


  static Future<Uint8List> convertNV21toImage(CameraImage image, CameraLensDirection lensDirection) async {
    try {
      if(Platform.isIOS){
        return await _convertBGRA8888ToImage(image, lensDirection);
      }
      var width = image.width;
      var height = image.height;
      var nv21Data = image.planes[0].bytes;
      final int frameSize = width * height;
      var img = img_lib.Image(width: width, height: height);
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int index = y * width + x;
          final int yValue = nv21Data[index] & 0xFF;
          int uvIndex = frameSize + (y ~/ 2 * width + x ~/ 2 * 2);
          final int vValue = nv21Data[uvIndex] & 0xFF;
          final int uValue = nv21Data[uvIndex + 1] & 0xFF;
          int uPrime = uValue - 128;
          int vPrime = vValue - 128;
          int r = (yValue + 1.370705 * vPrime).round().clamp(0, 255);
          int g = (yValue - 0.337633 * uPrime - 0.698001 * vPrime).round().clamp(0, 255);
          int b = (yValue + 1.732446 * uPrime).round().clamp(0, 255);

          img.setPixelRgb(x, y, r, g, b);
        }
      }
      img_lib.JpegEncoder jpegEncoder = img_lib.JpegEncoder();
      List<int> jpeg = jpegEncoder.encode(img_lib.copyRotate(img, angle: (lensDirection == CameraLensDirection.front) ? -90 : 90));
      return Uint8List.fromList(jpeg);
    } catch (e) {
      debugPrint('Error converting NV21 to image: $e');
      return Uint8List(0);
    }
  }
}