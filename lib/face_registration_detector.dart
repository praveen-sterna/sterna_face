import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:sterna_face/face_helpers.dart';
import 'camera.dart';
import 'face_data.dart';
import 'face_detector_painter.dart';

class FaceRegistrationDetectorView extends StatefulWidget {
  final Function(FaceData) onSuccess;
  const FaceRegistrationDetectorView({super.key, required this.onSuccess});

  @override
  State<FaceRegistrationDetectorView> createState() => _FaceRegistrationDetectorViewState();
}

class _FaceRegistrationDetectorViewState extends State<FaceRegistrationDetectorView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 1.0
    ),
  );
  FaceAngle _angle = FaceAngle.center;
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  FaceData _faceData = FaceData(
    centerAngleInputImage: null,
    rightAngleInputImage:  null,
    leftAngleInputImage: null
  );
  String _msg = "";
  bool _isCaptured = false;
  Timer? _timer;
  final CameraLensDirection cameraLensDirection = CameraLensDirection.front;
  final String _noFace = "No faces detected, Please adjust your position.";
  final String _multipleFace = "Multiple faces detected, Please make sure only one person is in the frame.";
  final String _turnLeft = "Please turn your head to the left side.";
  final String _turnRight = "Please turn your head to the right side.";
  final String _faceCaptured = "Thank you! We have captured your face identity data.";

  @override
  initState(){
    _init();
    super.initState();
  }

  void _startTimer(){
    _timer = Timer.periodic(const Duration(seconds: 1), (periodicTimer) {
      if (periodicTimer.tick >= 300) {
        _timer?.cancel();
        periodicTimer.cancel();
        Navigator.pop(context);
      }
    });
  }

  Future<void> _init() async {
    _faceData = FaceData(
        centerAngleInputImage: null,
        rightAngleInputImage:  null,
        leftAngleInputImage: null
    );
    _startTimer();
    _msg = "Hello! Please look straight at the camera.";
    _canProcess = true;
    setState(() {});
  }

  Future<void> faceNotFound() async{
    _msg = _noFace;
  }

  Future<void> multiFacesFound() async{
    _msg = _multipleFace;
  }

  Future<void> faceFound(List<Face> faces, CameraImage image) async{
    if(faces.isEmpty)return;
    final face =  faces.first;
    final headAngle = face.headEulerAngleY ?? 0.0;
    if((face.rightEyeOpenProbability ?? 0.0) < 0.5){
      _msg = "Open your left eye";
    }else if( (face.leftEyeOpenProbability ?? 0.0) < 0.5){
      _msg = "Open your right eye";
    }else if(_angle == FaceAngle.left) {
      if(headAngle < 30){
        _msg = _turnLeft;
      }else{
        _canProcess = false;
        _msg = "Perfect! Now, slightly Turn your head to right side";
        _faceData.leftAngleInputImage = FaceHelpers.convertNV21toImage(image, cameraLensDirection);
        _angle = FaceAngle.right;
        _canProcess = true;
      }
    }else if(_angle == FaceAngle.right) {
      if(headAngle > -30){
        _msg = _turnRight;
      }else{
        _canProcess = false;
        _msg = "Perfect! Now, Look straight at the camera";
        _faceData.rightAngleInputImage = FaceHelpers.convertNV21toImage(image, cameraLensDirection);
        _angle = FaceAngle.center;
        _canProcess = true;
      }
    }else if(_angle == FaceAngle.center){
      if(headAngle > 3 || headAngle < -3){
        _msg = "Look straight at the camera";
      }else {
        _canProcess = false;
        _msg = _faceCaptured;
        _faceData.centerAngleInputImage = FaceHelpers.convertNV21toImage(image, cameraLensDirection);
        await _dispose();
        _isCaptured = true;
        widget.onSuccess(_faceData);
        setState(() {});
      }
    }
  }


  Future<void> _processImage(InputImage inputImage, CameraImage image) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    final faces = await _faceDetector.processImage(inputImage);
    if(faces.isEmpty){
      if(_msg != _noFace) {
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
        cameraLensDirection,
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

  Future<void> _dispose() async{
    _canProcess = false;
    await _faceDetector.close();
    _timer?.cancel();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(_isCaptured){
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Colors.white,
        ),
      );
    }
    return Stack(
      children: [
        CameraView(
          customPaint: _customPaint,
          onImage: _processImage,
          initialCameraLensDirection: cameraLensDirection,
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
            child: Text(_msg, style: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.w500, fontSize: 15, height: 1.8),textAlign: TextAlign.center,),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(36.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Visibility(
                    visible: _msg == _turnRight,
                    child: const Icon(Icons.arrow_forward_rounded,size: 48,color: Colors.white,)
                ),
                Visibility(
                  visible: _msg == _turnLeft,
                  child: const Icon(Icons.arrow_back_rounded,size: 48,color: Colors.white,),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}