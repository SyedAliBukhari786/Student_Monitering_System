import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentReportDetails extends StatefulWidget {
  final String reportId;
  final String studentId;

  const StudentReportDetails({
    Key? key,
    required this.reportId,
    required this.studentId,
  }) : super(key: key);

  @override
  _StudentReportDetailsState createState() => _StudentReportDetailsState();
}

class _StudentReportDetailsState extends State<StudentReportDetails> {
  Future<Map<String, dynamic>> _fetchReportDetails() async {
    Map<String, dynamic> reportDetails = {};

    try {
      DocumentSnapshot reportDoc = await FirebaseFirestore.instance
          .collection('TestReports')
          .doc(widget.reportId)
          .get();

      DocumentSnapshot studentDoc = await reportDoc.reference
          .collection('Reports')
          .doc(widget.studentId)
          .get();

      if (studentDoc.exists) {
        var studentData = await FirebaseFirestore.instance
            .collection('Students')
            .doc(widget.studentId)
            .get();

        var studentName = studentData['StudentName'];
        reportDetails = {
          'StudentId': widget.studentId,
          'StudentName': studentName,
          'ObtainedMarks': studentDoc['ObtainedMarks'],
          'TotalMarks': reportDoc['TotalMarks'],
        };
      }
    } catch (e) {
      print("Error fetching report details: $e");
    }

    return reportDetails;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Details'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchReportDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No details found'));
          } else {
            var reportDetails = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text(reportDetails['StudentName']),
                  subtitle: Text('Marks: ${reportDetails['ObtainedMarks']} / ${reportDetails['TotalMarks']}'),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
