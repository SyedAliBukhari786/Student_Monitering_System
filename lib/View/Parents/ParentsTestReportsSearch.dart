
import 'package:childmoniteringsystem/View/Parents/student_test_details.dart';
import 'package:childmoniteringsystem/View/Studentactivitytrackers/reportdetails.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
class ParentsTestReportsSearch extends StatefulWidget {
  final String classId;
  final String studentId;

  const ParentsTestReportsSearch({
    Key? key,
    required this.classId,
    required this.studentId,
  }) : super(key: key);
  @override
  _ParentsTestReportsSearchState createState() => _ParentsTestReportsSearchState();
}

class _ParentsTestReportsSearchState extends State<ParentsTestReportsSearch> {
  final _dateController = TextEditingController();
  final _subjectController = TextEditingController();
  List<Map<String, dynamic>> reports = [];

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

  Future<void> _searchReports() async {
    if (_dateController.text.isEmpty && _subjectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter at least one criteria to search')));
      return;
    }

    try {
      Query query = FirebaseFirestore.instance.collection('TestReports').where('Class_ID', isEqualTo: widget.classId);

      if (_dateController.text.isNotEmpty) {
        DateTime selectedDate = DateTime.parse(_dateController.text);
        DateTime timestampDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 0, 0, 0);
        Timestamp timestamp = Timestamp.fromDate(timestampDate);
        query = query.where('Date', isEqualTo: timestamp);
      }

      if (_subjectController.text.isNotEmpty) {
        query = query.where('Subject', isEqualTo: _subjectController.text);
      }

      QuerySnapshot querySnapshot = await query.get();
      reports = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'Subject': doc['Subject'],
          'Date': (doc['Date'] as Timestamp).toDate(),
        };
      }).toList();

      setState(() {});
    } catch (e) {
      print("Error fetching reports: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching reports')));
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
        title: Text('Smart Search'),
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
            TextField(
              controller: _subjectController,
              decoration: _inputDecoration(hintText: 'Subject', icon: Icons.book),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _searchReports,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text('Search', style:  TextStyle(color: Colors.white),),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  return GestureDetector(onTap: () {

                    _navigateToReportDetails(reports[index]['id']);

                  },
                    child: ListTile(
                      title: Text(reports[index]['Subject']),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(reports[index]['Date'])),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _navigateToReportDetails(String reportId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StudentReportDetails(reportId: reportId, studentId: widget.studentId,)),
    );
  }
}

