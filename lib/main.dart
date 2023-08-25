import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sterna_face/face_verification_detector.dart';

void main(){
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       debugShowCheckedModeBanner: false,
       home: Scaffold(
         appBar: AppBar(),
         body: FaceVerificationDetectorView(
           onSuccess: (_){},
           cameraLensDirection: CameraLensDirection.front,
         ),
       )
    );
  }
}
