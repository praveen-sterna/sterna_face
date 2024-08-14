import 'package:flutter/material.dart';

class FaceDetectorLoader extends StatelessWidget {
  const FaceDetectorLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: const Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 25,
            width: 25,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16,),
          Text("Setting up camera, hold on...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),)
        ],
      ),
    );
  }
}
