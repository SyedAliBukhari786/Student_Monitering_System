import 'package:childmoniteringsystem/View/passfailprediction.dart';
import 'package:childmoniteringsystem/View/studentactivityview.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class StudentDetails extends StatefulWidget {
  final String className;

  const StudentDetails({Key? key, required this.className}) : super(key: key);

  @override
  _StudentDetailsState createState() => _StudentDetailsState();
}

class _StudentDetailsState extends State<StudentDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> students = [];
  String? classId;

  @override
  void initState() {
    super.initState();
    fetchClassIdAndStudents();
  }

  Future<void> fetchClassIdAndStudents() async {
    try {
      // Fetch class ID
      QuerySnapshot classSnapshot = await _firestore
          .collection('Classes')
          .where('className', isEqualTo: widget.className)
          .limit(1)
          .get();

      if (classSnapshot.docs.isNotEmpty) {
        setState(() {
          classId = classSnapshot.docs.first.id;
        });

        // Fetch students
        QuerySnapshot studentSnapshot = await _firestore
            .collection('Students')
            .where('Class', isEqualTo: widget.className)
            .get();

        setState(() {
          students = studentSnapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
              .toList();
        });
      } else {
        print("Class not found");
      }
    } catch (e) {
      print("Error fetching class ID and students: $e");
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      await _firestore.collection('Students').doc(id).delete();
      setState(() {
        students.removeWhere((student) => student['id'] == id);
      });
    } catch (e) {
      print("Error deleting student: $e");
    }
  }

  Future<void> editStudent(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('Students').doc(id).update(data);
      fetchClassIdAndStudents(); // Refresh the list
    } catch (e) {
      print("Error updating student: $e");
    }
  }

  void showDeleteConfirmationDialog(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Student'),
        content: Text('Are you sure you want to delete this student?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              deleteStudent(id);
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void showEditDialog(Map<String, dynamic> student) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController(text: student['StudentName']);
    final TextEditingController rollNoController = TextEditingController(text: student['Rollno']);
    final TextEditingController parentContactController = TextEditingController(text: student['ParentContact']);
    final TextEditingController parentNameController = TextEditingController(text: student['ParentName']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Student'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Student Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter student name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: rollNoController,
                  decoration: InputDecoration(
                    labelText: 'Roll No',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter roll number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: parentContactController,
                  decoration: InputDecoration(
                    labelText: 'Parent Contact',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) {
                    if (value == null || value.length != 11) {
                      return 'Please enter a valid 11-digit phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: parentNameController,
                  decoration: InputDecoration(
                    labelText: 'Parent Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter parent name';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final updatedData = {
                  'StudentName': nameController.text,
                  'Rollno': rollNoController.text,
                  'ParentContact': parentContactController.text,
                  'ParentName': parentNameController.text,
                };
                editStudent(student['id'], updatedData);
                Navigator.pop(context);
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Students in ${widget.className}'),
        backgroundColor: Colors.grey[200],
      ),
      body: students.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                title: Center(
                  child: Column(
                    children: [
                      student['imageUrl'] != null
                          ? Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          image: DecorationImage(
                            image: NetworkImage(student['imageUrl']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                          : Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(child: Text('No image')),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset("assets/student.png", height: 20, width: 20),
                          Text(
                            student['StudentName'] ?? 'No Name',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.admin_panel_settings_outlined, color: Colors.green),
                            onPressed: classId != null
                                ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PassFailPrediction(
                                    studentId: student['id'],
                                    classId: classId!,
                                  ),
                                ),
                              );
                            }
                                : null,
                          ),
                          IconButton(
                            icon: Icon(Icons.not_accessible, color: Colors.red),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => StudentActivityview()),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Roll No: ${student['Rollno'] ?? 'N/A'}'),
                    Text('Parent Contact: ${student['ParentContact'] ?? 'N/A'}'),
                    Text('Parent Name: ${student['ParentName'] ?? 'N/A'}'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.green),
                          onPressed: () => showEditDialog(student),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              showDeleteConfirmationDialog(student['id']),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  // You can add further navigation to student details here
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
