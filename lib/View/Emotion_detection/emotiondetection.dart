import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class EmotionDetection extends StatefulWidget {
  const EmotionDetection({super.key});

  @override
  State<EmotionDetection> createState() => _EmotionDetectionState();
}

class _EmotionDetectionState extends State<EmotionDetection> {
  File? _image;
  String? _prediction;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        print('Image selected: ${_image!.path}');
        _predictEmotion();
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }
  String emotiondetection = '';

  @override
  void initState() {
    super.initState();
    _fetchPassFailUrl();
  }

  Future<void> _fetchPassFailUrl() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('FlaskApi').doc('h2itw5fROb31PbFqYfJ7').get();
      setState(() {
        emotiondetection = snapshot['emotiondetection'];
      });
      print('Pass Fail URL: $emotiondetection');
    } catch (e) {
      print('Error fetching URL: $e');
    }
  }
  Future<void> _predictEmotion() async {
    if (_image == null) return;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$emotiondetection/predict'),
      );
      request.files.add(
        await http.MultipartFile.fromPath('file', _image!.path),
      );

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        setState(() {
          _prediction = json.decode(responseString)['emotion'];
        });
        print('Prediction received: $_prediction');
      } else {
        setState(() {
          _prediction = 'Error: ${response.statusCode} - ${responseString}';
        });
        print('Error from server: ${response.statusCode} - ${responseString}');
      }
    } catch (e) {
      setState(() {
        _prediction = 'Failed to predict emotion: $e';
      });
      print('Error predicting emotion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion Detection'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_image != null)
                Image.file(_image!)
              else
                const Text('No image selected.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Pick Image from Gallery'),
              ),
              const SizedBox(height: 16),
              if (_prediction != null)
                Text(
                  'Prediction: $_prediction',
                  style: const TextStyle(fontSize: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
