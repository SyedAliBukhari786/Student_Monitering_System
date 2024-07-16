import 'package:flutter/material.dart';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MarkAttendance extends StatefulWidget {
  final String classId;

  const MarkAttendance({Key? key, required this.classId}) : super(key: key);

  @override
  _MarkAttendanceState createState() => _MarkAttendanceState();
}

class _MarkAttendanceState extends State<MarkAttendance> {
  final _dateController = TextEditingController();
  List<Map<String, dynamic>> students = [];
  Map<String, String> attendanceStatus = {};

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Students')
          .where('Class_ID', isEqualTo: widget.classId)
          .get();
      students = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        attendanceStatus[doc.id] = 'Present';
        return {
          'id': doc.id,
          'name': data['StudentName'] as String,
        };
      }).toList();
      setState(() {});
    } catch (e) {
      print("Error fetching students: $e");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _clearDate() {
    setState(() {
      _dateController.clear();
    });
  }

  Future<void> _saveAttendance() async {
    if (_dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a date')));
      return;
    }

    try {
      DateTime selectedDate = DateTime.parse(_dateController.text);
      DateTime timestampDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 0, 0, 0);
      Timestamp timestamp = Timestamp.fromDate(timestampDate);

      // Check for existing attendance on the selected date
      QuerySnapshot existingRecords = await FirebaseFirestore.instance
          .collection('Attendance')
          .where('Class_ID', isEqualTo: widget.classId)
          .where('Date', isEqualTo: timestamp)
          .get();

      if (existingRecords.docs.isNotEmpty) {
        // Delete existing records
        for (var doc in existingRecords.docs) {
          await doc.reference.delete();
        }
      }

      // Save new attendance
      DocumentReference attendanceRef = await FirebaseFirestore.instance.collection('Attendance').add({
        'Class_ID': widget.classId,
        'Date': timestamp,
        'Timestamp': FieldValue.serverTimestamp(),
      });

      for (var student in students) {
        String studentId = student['id'];
        await attendanceRef.collection('Report').doc(studentId).set({
          'Status': attendanceStatus[studentId],
          'Student_ID': studentId,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Attendance saved successfully')));
      Navigator.pop(context);
    } catch (e) {
      print("Error saving attendance: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving attendance')));
    }
  }

  InputDecoration _inputDecoration({required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: Colors.green),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.blue),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.blue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.blue),
      ),
      suffixIcon: hintText == 'Select Date' ? IconButton(
        icon: Icon(Icons.clear, color: Colors.red),
        onPressed: _clearDate,
      ) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mark Attendance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _dateController,
              decoration: _inputDecoration(hintText: 'Select Date', icon: Icons.calendar_today),
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(students[index]['name']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: 'Present',
                          groupValue: attendanceStatus[students[index]['id']],
                          onChanged: (value) {
                            setState(() {
                              attendanceStatus[students[index]['id']] = value!;
                            });
                          },
                        ),
                        Text('Present'),
                        Radio<String>(
                          value: 'Absent',
                          groupValue: attendanceStatus[students[index]['id']],
                          onChanged: (value) {
                            setState(() {
                              attendanceStatus[students[index]['id']] = value!;
                            });
                          },
                        ),
                        Text('Absent'),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
