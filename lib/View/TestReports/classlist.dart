import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../StudentDetails.dart';
import 'marksentery.dart';  // Make sure the import path is correct

class classeslist extends StatefulWidget {
  const classeslist({super.key});

  @override
  State<classeslist> createState() => _classeslistState();
}

class _classeslistState extends State<classeslist> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Marksentery(classId: classes[index]['id']!),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
