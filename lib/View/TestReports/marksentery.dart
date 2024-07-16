import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Marksentery extends StatefulWidget {
  final String classId;

  Marksentery({required this.classId});

  @override
  _MarksenteryState createState() => _MarksenteryState();
}

class _MarksenteryState extends State<Marksentery> {
  final _dateController = TextEditingController();
  final _subjectController = TextEditingController();
  final _totalMarksController = TextEditingController();
  List<Map<String, dynamic>> students = [];
  Map<String, TextEditingController> marksControllers = {};

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
        marksControllers[doc.id] = TextEditingController();
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
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitData() async {
    if (_dateController.text.isEmpty || _subjectController.text.isEmpty || _totalMarksController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all the required fields')));
      return;
    }

    try {
      // Parse the date and set a constant time (e.g., 00:00:00)
      DateTime selectedDate = DateTime.parse(_dateController.text);
      DateTime timestampDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 0, 0, 0);
      Timestamp timestamp = Timestamp.fromDate(timestampDate);

      // Create the main document in TestReports
      DocumentReference testReportRef = await FirebaseFirestore.instance.collection('TestReports').add({
        'Class_ID': widget.classId,
        'TotalMarks': int.parse(_totalMarksController.text),
        'Subject': _subjectController.text,
        'Date': timestamp,
        'Timestamp': FieldValue.serverTimestamp(),
      });

      // Add documents to the sub-collection Reports
      for (var student in students) {
        String studentId = student['id'];
        int obtainedMarks = int.tryParse(marksControllers[studentId]?.text ?? '') ?? 0;
        await testReportRef.collection('Reports').doc(studentId).set({
          'Student_ID': studentId,
          'ObtainedMarks': obtainedMarks,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data submitted successfully')));
      Navigator.pop(context);
    } catch (e) {
      print("Error submitting data: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting data')));
    }
  }


  InputDecoration _inputDecoration({required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: Colors.green,),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Marks Entry'),
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
              decoration: _inputDecoration(hintText: 'Subject Name', icon: Icons.book),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _totalMarksController,
              decoration: _inputDecoration(hintText: 'Total Marks', icon: Icons.grade),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(students[index]['name']),
                      trailing: SizedBox(
                        width: 100,
                        child: TextField(
                          controller: marksControllers[students[index]['id']],
                          decoration: InputDecoration(
                            hintText: 'Marks',
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
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
