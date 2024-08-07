import 'package:childmoniteringsystem/View/facialrecongnitaion.dart';
import 'package:flutter/material.dart';

import 'Emotion_detection/emotiondetection.dart';
import 'HateSpeechDetector.dart';


class Superadminpannerl extends StatefulWidget {
  const Superadminpannerl({super.key});

  @override
  State<Superadminpannerl> createState() => _SuperadminpannerlState();
}

class _SuperadminpannerlState extends State<Superadminpannerl> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Superadmin Panel'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              SizedBox(height: 30), // Top padding
              _buildContainer('Hate Speech'),
              SizedBox(height: 30),
              _buildContainer('Facial Recognition'),
              SizedBox(height: 30),
              _buildContainer('Emotion Detection'),
              SizedBox(height: 30), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContainer(String text) {
    return GestureDetector(
      onTap: () {
        if(text=="Hate Speech"){

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SpeechScreen()),
          );
        }
        else if (text=="Facial Recognition") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CompareScreen()),
          );
        }
        else if (text=="Emotion Detection") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EmotionDetection()),
          );
        }


      },
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
