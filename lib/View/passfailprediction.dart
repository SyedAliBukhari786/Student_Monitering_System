import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PassFailPrediction extends StatelessWidget {
  final String studentId;
  final String classId;

  const PassFailPrediction({
    Key? key,
    required this.studentId,
    required this.classId,
  }) : super(key: key);

  Future<double> _calculateAttendancePercentage() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    int totalClasses = 0;
    int presentCount = 0;

    try {
      QuerySnapshot attendanceSnapshot = await _firestore
          .collection('Attendance')
          .where('Class_ID', isEqualTo: classId)
          .get();

      for (var doc in attendanceSnapshot.docs) {
        DocumentSnapshot reportSnapshot = await _firestore
            .collection('Attendance')
            .doc(doc.id)
            .collection('Report')
            .doc(studentId)
            .get();

        if (reportSnapshot.exists) {
          totalClasses++;
          var data = reportSnapshot.data() as Map<String, dynamic>?;
          if (data?['Status'] == 'Present') {
            presentCount++;
          }
        }
      }

      if (totalClasses == 0) return 0.0;
      return (presentCount / totalClasses) * 100;
    } catch (e) {
      print("Error fetching attendance: $e");
      return 0.0;
    }
  }

  Future<double> _calculateReportPercentage() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    int totalMarks = 0;
    int obtainedMarks = 0;

    try {
      QuerySnapshot testReportsSnapshot = await _firestore
          .collection('TestReports')
          .where('Class_ID', isEqualTo: classId)
          .get();

      for (var doc in testReportsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>?;
        int testTotalMarks = data?['TotalMarks'] ?? 0;
        totalMarks += testTotalMarks;

        DocumentSnapshot reportSnapshot = await _firestore
            .collection('TestReports')
            .doc(doc.id)
            .collection('Reports')
            .doc(studentId)
            .get();

        if (reportSnapshot.exists) {
          var reportData = reportSnapshot.data() as Map<String, dynamic>?;
          obtainedMarks += (reportData?['ObtainedMarks'] as num? ?? 0).toInt();
        }
      }

      if (totalMarks == 0) return 0.0;
      return (obtainedMarks / totalMarks) * 100;
    } catch (e) {
      print("Error fetching reports: $e");
      return 0.0;
    }
  }

  Future<bool> _getPrediction(double attendancePercentage, double reportPercentage) async {
    final response = await http.post(
      Uri.parse('https://5072-118-107-131-191.ngrok-free.app/predict'), // Update with your Flask server address
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'attendance_percentage': attendancePercentage,
        'test_marks_percentage': reportPercentage,
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['pass'];
    } else {
      throw Exception('Failed to load prediction');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Center(child: Text('Prediction')),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: FutureBuilder<List<double>>(
          future: Future.wait([
            _calculateAttendancePercentage(),
            _calculateReportPercentage(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Text('No data available');
            } else {
              final attendancePercentage = snapshot.data![0];
              final reportPercentage = snapshot.data![1];
              return FutureBuilder<bool>(
                future: _getPrediction(attendancePercentage, reportPercentage),
                builder: (context, predictionSnapshot) {
                  if (predictionSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (predictionSnapshot.hasError) {
                    return Text('Error: ${predictionSnapshot.error}');
                  } else if (!predictionSnapshot.hasData || predictionSnapshot.data == null) {
                    return Text('No prediction available');
                  } else {
                    final prediction = predictionSnapshot.data!;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: 10,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 150,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.blue),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: 2,),
                                  Text("Attendance", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),),
                                  SizedBox(height: 2,),
                                  Center(
                                    child: Text(
                                      'Percentage:\n${attendancePercentage.toStringAsFixed(2)}%',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 20,),
                            Container(
                              height: 150,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.blue),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: 2,),
                                  Text("Reports", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),),
                                  SizedBox(height: 2,),
                                  Center(
                                    child: Text(
                                      'Percentage:\n${reportPercentage.toStringAsFixed(2)}%',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20,),
                        Container(
                          height: 100,
                          width: 200,
                          decoration: BoxDecoration(
                            color: prediction ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              prediction ? 'PASS' : 'FAIL',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              );
            }
          },
        ),
      ),
    );
  }}