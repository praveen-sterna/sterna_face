import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:sterna_face/face_helpers.dart';
import 'camera.dart';
import 'face_data.dart';
import 'face_detector_painter.dart';

class FaceVerificationDetectorView extends StatefulWidget {
  final Function(FaceData) onSuccess;
  const FaceVerificationDetectorView({super.key, required this.onSuccess});

  @override
  State<FaceVerificationDetectorView> createState() => _FaceVerificationDetectorViewState();
}

class _FaceVerificationDetectorViewState extends State<FaceVerificationDetectorView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 1.0
    ),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  final CameraLensDirection _cameraLensDirection = CameraLensDirection.front;
  final FaceData _faceData = FaceData();
  String _msg = "";
  bool _isCaptured = false;
  Timer? _timer;
  int time = 300;

  @override
  initState(){
    _init();
    super.initState();
  }

  void _startTimer(){
    _timer = Timer.periodic(const Duration(seconds: 1), (periodicTimer) {
      if (time <= 0) {
        _timer?.cancel();
        periodicTimer.cancel();
        FaceHelpers.showToast("Session expired");
        //Navigator.pop(context);
      } else {
        time = 300 - periodicTimer.tick;
        setState(() {});
      }
    });
  }

  Future<void> _init() async {
    _startTimer();
    _msg = "Hello ! Look straight on the camera";
    _canProcess = true;
    setState(() {});
  }

  Future<void> faceNotFound() async{
    _msg = "No faces found";
    setState(() {});
  }

  Future<void> multiFacesFound() async{
    _msg = "Multiple faces found";
    setState(() {});
  }

  Future<void> faceFound(List<Face> faces, CameraImage image) async{
    if(faces.isEmpty)return;
    final face =  faces.first;
    if(!((face.headEulerAngleZ ?? 0.0) > -2 || (face.headEulerAngleZ ?? 0.0) < 2)){
      _msg = "Look Straight";
    }else {
      if ((face.headEulerAngleY ?? 0.0) > 3) {
        _msg = "Turn right";
      } else if ((face.headEulerAngleY ?? 0.0) < -3) {
        _msg = "Turn left";
      } else {
        if((face.rightEyeOpenProbability ?? 0.0) < 0.5){
          _msg = "Open your left eye";
        }else if ((face.leftEyeOpenProbability ?? 0.0) < 0.5){
          _msg = "Open your right eye";
        }else{
          _msg = "Thank you! We have captured your face identity data.";
          _faceData.centerAngleInputImage = image;
          _dispose();
          _isCaptured = true;
          setState(() {});
          widget.onSuccess(_faceData);
        }
      }
    }
  }

  Future<void> _processImage(InputImage inputImage, CameraImage image) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    final faces = await _faceDetector.processImage(inputImage);
    if(faces.isEmpty){
      if(_msg != "No faces found") {
        faceNotFound();
      }
    }else if(faces.length > 1) {
      multiFacesFound();
    }else{
      debugPrint("-------face found------");
      faceFound(faces, image);
    }
    if (inputImage.metadata?.size != null && inputImage.metadata?.rotation != null) {
      final painter = FaceDetectorPainter(
        faces,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _dispose(){
    _canProcess = false;
    _faceDetector.close();
    _timer?.cancel();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return (_isCaptured) ? const Center(
      child: CircularProgressIndicator(
        strokeWidth: 3,
        color: Colors.white,
      ),
    ) : Stack(
      fit: StackFit.expand,
      children: [
        CameraView(
          customPaint: _customPaint,
          onImage: _processImage,
          initialCameraLensDirection: _cameraLensDirection,
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20)
                    ),
                    height: 4,
                    width: 50,
                  ),
                ),
                const SizedBox(height: 24,),
                Text(_msg, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16, height: 1.8),textAlign: TextAlign.center,),
                const SizedBox(height: 8,),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Your Session will expires in ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w300, fontSize: 13),),
                    Text(FaceHelpers.formatSecondsToMinutes(time), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 15),),
                  ],
                ),
                const SizedBox(height: 8,),
              ],
            ),
          ),
        )
      ],
    );
  }
}