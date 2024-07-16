import 'package:childmoniteringsystem/View/passfailprediction.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

import '../Loginas.dart';
import '../Studentactivitytrackers/advancesearchatteandance.dart';
import '../Teachers/TeachersClassselection.dart';
import '../Teachershatespeechview.dart';
import '../studentactivityview.dart';
import 'ParentsTestReportsSearch.dart';

class Parentsdashboard extends StatefulWidget {
  const Parentsdashboard({super.key});

  @override
  State<Parentsdashboard> createState() => _ParentsdashboardState();
}

class _ParentsdashboardState extends State<Parentsdashboard> {
  late String currentUserId = '';
  late String parentName = '';
  late String parentContact = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    getCurrentUserId();
  }

  Future<void> fetchStudents() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('Students')
          .where('ParentContact', isEqualTo: parentContact)
          .get();

      List<Map<String, dynamic>> studentData = [];

      for (var doc in querySnapshot.docs) {
        var student = doc.data() as Map<String, dynamic>;
        student['id'] = doc.id;
        if (student.containsKey('Class_ID')) {
          DocumentSnapshot classDoc = await _firestore.collection('Classes').doc(student['Class_ID']).get();
          if (classDoc.exists) {
            student['className'] = classDoc['className'] ?? 'Unknown Class';
          } else {
            student['className'] = 'Unknown Class';
          }
        } else {
          student['className'] = 'No Class ID';
        }
        studentData.add(student);
      }

      setState(() {
        students = studentData;
      });

      // Debug print to verify data
      print("Students Data: $students");
    } catch (e) {
      print("Error fetching students: $e");
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState!.openDrawer();
  }

  Future<void> getCurrentUserId() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    if (user != null) {
      currentUserId = user.uid;
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentSnapshot parentSnapshot = await firestore.collection('Parents').doc(currentUserId).get();

      if (parentSnapshot.exists) {
        setState(() {
          parentName = parentSnapshot.get('parentName');
          parentContact = parentSnapshot.get('parentContact');
        });
        fetchStudents(); // Call fetchStudents after parentContact is set
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                ),
                child: Center(
                  child: Container(
                    height: 120,
                    width: 120,
                    child: Lottie.asset("assets/students.json"),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                    ),
                  ),
                ),
              ),
              ListTile(
                title: Row(
                  children: [
                    Text('Logout', style: TextStyle(color: Colors.red)),
                    SizedBox(width: 10),
                    Icon(Icons.login_sharp, color: Colors.red)
                  ],
                ),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Selectin()),
                        (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
          ),
        ),
        backgroundColor: Colors.grey[100],
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                child: Column(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                child: Padding(
                                  padding: const EdgeInsets.all(7.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              _openDrawer();
                                            },
                                            child: Icon(
                                              Icons.menu_open,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "Hello,",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 25,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "$parentName",
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                child: Center(
                                  child: Lottie.asset('assets/students.json'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Center(
                        child: Container(
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: _buildCalendar(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(50),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Container(
                child: Text(
                  "Your Children",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(3.0),
                child: Container(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: students.isEmpty
                            ? Center(child: CircularProgressIndicator())
                            : ListView.builder(
                          shrinkWrap: true,
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
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                                "assets/student.png",
                                                height: 20,
                                                width: 20),
                                            Text(
                                              student['StudentName'] ??
                                                  'No Name',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight:
                                                FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),

                                      ],
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Roll No: ${student['Rollno'] ?? 'N/A'}'),
                                      Text(
                                          'Class Name: ${student['className'] ?? 'N/A'}'),
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                                Icons
                                                    .admin_panel_settings_outlined,
                                                color: Colors.green),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ParentsTestReportsSearch(studentId: student['id'],classId: student['Class_ID'],),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                                Icons.admin_panel_settings_outlined,
                                                color: Colors.blue),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PassFailPrediction(studentId: student['id'], classId:student['Class_ID']),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                                Icons.app_registration,
                                                color: Colors.blue),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SmartSearchAttendance(),
                                                ),
                                              );
                                            },
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
                      ),
                    ],
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey[100],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCalendar() {
    List<Widget> calendarItems = [];
    DateTime now = DateTime.now();

    for (int i = -3; i < 4; i++) {
      DateTime date = now.add(Duration(days: i));
      bool isCurrentDate = now.day == date.day && now.month == date.month && now.year == date.year;
      calendarItems.add(_buildCalendarItem(date, isCurrentDate));
    }

    return calendarItems;
  }

  Widget _buildCalendarItem(DateTime date, bool isCurrentDate) {
    TextStyle textStyle = TextStyle(
      color: isCurrentDate ? Colors.white : Colors.white,
      fontWeight: isCurrentDate ? FontWeight.bold : FontWeight.normal,
    );

    BoxDecoration decoration = isCurrentDate
        ? BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.circular(10.0),
    )
        : BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10.0),
    );

    return Container(
      decoration: decoration,
      padding: EdgeInsets.all(5.0),
      child: Column(
        children: [
          SizedBox(height: 30),
          Text(
            DateFormat.E().format(date),
            style: textStyle,
          ),
          SizedBox(height: 5),
          Text(
            DateFormat.d().format(date),
            style: textStyle,
          ),
        ],
      ),
    );
  }
}
