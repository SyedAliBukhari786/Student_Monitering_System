import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Attendance/markattedance.dart';
import '../TestReports/marksentery.dart';

class Teachersclassselection extends StatefulWidget {
  final String category;

  const Teachersclassselection({Key? key, required this.category}) : super(key: key);

  @override
  State<Teachersclassselection> createState() => _TeachersclassselectionState();
}

class _TeachersclassselectionState extends State<Teachersclassselection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, String>> classes = [];
  List<String> list_type = ["Select Class"];

  @override
  void initState() {
    super.initState();
    fetchClassNames();
  }

  Future<void> fetchClassNames() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection("Classes").orderBy("className", descending: false).get();
      classes = querySnapshot.docs.map((doc) => {
        'id': doc.id,
        'className': doc['className'] as String,
      }).toList();
      setState(() {
        list_type.addAll(classes.map((classData) => classData['className']!).toList());
        print(list_type);
      });
    } catch (e) {
      print("Error fetching class names: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: classes.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(classes[index]['className']!),
              trailing: Icon(Icons.arrow_forward, color: Colors.green,),
              onTap: () {
                if(widget.category=="Mark Attendance") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MarkAttendance(classId: classes[index]['id']!),
                    ),
                  );
                } else  if(widget.category=="Test Reports") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Marksentery(classId: classes[index]['id']!),
                    ),
                  );
                }

              },
            ),
          );
        },
      ),
    );
  }
}
