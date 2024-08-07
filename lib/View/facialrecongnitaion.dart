import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CompareScreen extends StatefulWidget {
  @override
  _CompareScreenState createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {


  @override
  void initState() {
    super.initState();

    _fetchHateSpeechUrl();
  }

  Future<void> _fetchHateSpeechUrl() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('FlaskApi').doc('Ypiz75N4PjobAOlEJuN5').get();
      setState(() {
        _facedetectionUrl = snapshot['facerecongination'];
      });
      print('Hate Speech URL: $_facedetectionUrl');
    } catch (e) {
      print('Error fetching URL: $e');
    }
  }
  String _facedetectionUrl = '';
  File? _image;
  final picker = ImagePicker();
  String _result = "";
  String? _matchedDocId;
  Map<String, dynamic>? _matchedDetails;
  bool _isComparing = false;

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _compareImages() async {
    if (_image == null) {
      setState(() {
        _result = "Please select an image.";
      });
      return;
    }

    setState(() {
      _isComparing = true;
    });

    try {
      // Fetch image URLs and doc IDs from Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('Students').get();
      List<QueryDocumentSnapshot> documents = snapshot.docs;

      for (var doc in documents) {
        String imageUrl = doc['imageUrl'];
        String docId = doc.id;
        Map<String, dynamic> details = doc.data() as Map<String, dynamic>;

        // Compare with the selected image
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$_facedetectionUrl/compare'), // Your Flask API URL
        );
        request.fields['imageUrl'] = imageUrl;
        request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

        var response = await request.send();

        if (response.statusCode == 200) {
          var responseData = await response.stream.bytesToString();
          var result = jsonDecode(responseData);

          if (result['result'] == 'same') {
            setState(() {
              _matchedDocId = docId;
              _matchedDetails = details;
              _result = "Match found!";
              _isComparing = false;
            });
            _showMatchedDetails();
            return; // Exit the loop once a match is found
          }
        }
      }

      setState(() {
        _result = "No match found.";
        _isComparing = false;
      });
      _showMatchedDetails();
    } catch (e) {
      setState(() {
        _result = "Exception occurred: $e";
        _isComparing = false;
      });
    }
  }

  void _showMatchedDetails() {
    if (_matchedDetails == null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("No Match Found"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _image = null;
                    _result = "";
                    _matchedDetails = null;
                  });
                },
                child: Text("Close"),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Matched Student Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(_matchedDetails!['imageUrl']),
              Text("Student Name: ${_matchedDetails!['StudentName']}"),
              Text("Class: ${_matchedDetails!['Class']}"),
              Text("Roll No: ${_matchedDetails!['Rollno']}"),
              Text("Parent Name: ${_matchedDetails!['ParentName']}"),
              Text("Parent Contact: ${_matchedDetails!['ParentContact']}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _image = null;
                  _result = "";
                  _matchedDetails = null;
                });
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search by Face'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _image == null
                    ? Center(child: Text('Select an image'))
                    : Image.file(_image!, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _compareImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Background color
              ),
              child: Text(
                'Search',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            _isComparing
                ? CircularProgressIndicator()
                : Text(_result),
          ],
        ),
      ),
    );
  }
}
