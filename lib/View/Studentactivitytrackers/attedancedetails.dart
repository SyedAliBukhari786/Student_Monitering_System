import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceDetails extends StatefulWidget {
  final String documentId;

  const AttendanceDetails({Key? key, required this.documentId}) : super(key: key);

  @override
  _AttendanceDetailsState createState() => _AttendanceDetailsState();
}

class _AttendanceDetailsState extends State<AttendanceDetails> {
  List<Map<String, dynamic>> studentsAttendance = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAttendanceDetails();
  }

  Future<void> fetchAttendanceDetails() async {
    try {
      print('Fetching attendance details for document ID: ${widget.documentId}');
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('Attendance')
          .doc(widget.documentId)
          .get();

      if (documentSnapshot.exists) {
        print('Document data: ${documentSnapshot.data()}');
        QuerySnapshot reportsSnapshot = await documentSnapshot.reference.collection('Report').get();
        print('Fetched ${reportsSnapshot.docs.length} reports.');
        List<Map<String, dynamic>> attendanceData = [];

        for (var doc in reportsSnapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          print('Report data: $data');
          attendanceData.add({
            'studentId': data['Student_ID'],
            'status': data['Status'],
          });
        }

        // Fetch student names in parallel
        for (var student in attendanceData) {
          DocumentSnapshot studentDoc = await FirebaseFirestore.instance
              .collection('Students')
              .doc(student['studentId'])
              .get();
          if (studentDoc.exists) {
            print('Student data: ${studentDoc.data()}');
            var studentData = studentDoc.data() as Map<String, dynamic>;
            student['studentName'] = studentData.containsKey('StudentName') ? studentData['StudentName'] : 'Unknown';
          } else {
            student['studentName'] = 'Unknown';
          }
        }

        setState(() {
          studentsAttendance = attendanceData;
        });

        print('Parsed ${studentsAttendance.length} student attendance records.');
      } else {
        print('Document does not exist.');
      }
    } catch (e) {
      print("Error fetching attendance details: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateAttendanceStatus(String studentId, String currentStatus) async {
    String? newStatus = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String selectedStatus = currentStatus;
        return AlertDialog(
          title: Text('Update Attendance Status'),
          content: DropdownButton<String>(
            value: selectedStatus,
            onChanged: (String? newValue) {
              selectedStatus = newValue!;
              setState(() {});
            },
            items: <String>['Present', 'Absent']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(selectedStatus);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );

    if (newStatus != null && newStatus != currentStatus) {
      // Update status in Firestore
      await FirebaseFirestore.instance
          .collection('Attendance')
          .doc(widget.documentId)
          .collection('Report')
          .doc(studentId)
          .update({'Status': newStatus});

      // Update status locally
      setState(() {
        studentsAttendance.firstWhere((student) => student['studentId'] == studentId)['status'] = newStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Details'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : studentsAttendance.isEmpty
          ? Center(child: Text('No attendance records found.'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: studentsAttendance.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: Text('Student Name: ${studentsAttendance[index]['studentName']}'),
                  subtitle: Text('Status: ${studentsAttendance[index]['status']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      _updateAttendanceStatus(
                        studentsAttendance[index]['studentId'],
                        studentsAttendance[index]['status'],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
