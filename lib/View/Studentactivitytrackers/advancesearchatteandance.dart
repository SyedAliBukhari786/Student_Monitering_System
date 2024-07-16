import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'attedancedetails.dart';


class SmartSearchAttendance extends StatefulWidget {
  @override
  _SmartSearchAttendanceState createState() => _SmartSearchAttendanceState();
}

class _SmartSearchAttendanceState extends State<SmartSearchAttendance> {
  final _dateController = TextEditingController();
  final _classController = TextEditingController();
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> searchResults = [];
  Map<String, String> classNamesMap = {};

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  Future<void> fetchClasses() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Classes').get();
      classes = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        String classId = doc.id;
        String className = data['className'] as String;
        classNamesMap[classId] = className;
        return {
          'id': classId,
          'name': className,
        };
      }).toList();
      setState(() {});
    } catch (e) {
      print("Error fetching classes: $e");
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

  Future<void> _searchAttendance() async {
    String selectedDate = _dateController.text;
    String selectedClassName = _classController.text;

    if (selectedDate.isEmpty && selectedClassName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter at least one criterion to search')));
      return;
    }

    Query query = FirebaseFirestore.instance.collection('Attendance');

    if (selectedDate.isNotEmpty) {
      DateTime date = DateTime.parse(selectedDate);
      DateTime timestampDate = DateTime(date.year, date.month, date.day, 0, 0, 0);
      Timestamp timestamp = Timestamp.fromDate(timestampDate);
      query = query.where('Date', isEqualTo: timestamp);
    }

    if (selectedClassName.isNotEmpty) {
      String classId = classes.firstWhere((classItem) => classItem['name'] == selectedClassName)['id'];
      query = query.where('Class_ID', isEqualTo: classId);
    }

    try {
      QuerySnapshot querySnapshot = await query.get();
      searchResults = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'classId': data['Class_ID'] as String,
          'date': (data['Date'] as Timestamp).toDate(),
        };
      }).toList();
      setState(() {});
    } catch (e) {
      print("Error searching attendance: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error searching attendance')));
    }
  }

  InputDecoration _inputDecoration({required String hintText, required IconData icon, bool isDate = false}) {
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
      suffixIcon: isDate ? IconButton(
        icon: Icon(Icons.clear, color: Colors.red),
        onPressed: _clearDate,
      ) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Search Attendance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _dateController,
              decoration: _inputDecoration(hintText: 'Select Date', icon: Icons.calendar_today, isDate: true),
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _classController,
              decoration: _inputDecoration(hintText: 'Class Name', icon: Icons.class_),
              readOnly: true,
              onTap: () async {
                String? selectedClass = await showDialog(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: Text('Select Class'),
                    children: classes.map((classItem) {
                      return SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, classItem['name']);
                        },
                        child: Text(classItem['name']),
                      );
                    }).toList(),
                  ),
                );
                if (selectedClass != null) {
                  setState(() {
                    _classController.text = selectedClass;
                  });
                }
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _searchAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text('Search'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  DateTime date = searchResults[index]['date'];
                  String formattedDate = DateFormat('yyyy-MM-dd').format(date);
                  String className = classNamesMap[searchResults[index]['classId']] ?? 'Unknown Class';
                  return ListTile(
                    title: Text('Class Name: $className'),
                    subtitle: Text('Date: $formattedDate'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AttendanceDetails(documentId: searchResults[index]['id']),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
