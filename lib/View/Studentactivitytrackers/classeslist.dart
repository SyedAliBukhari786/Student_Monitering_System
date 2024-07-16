import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

import 'advancesearchatteandance.dart';
import 'advancesearchreports.dart';

class Secondclasslist extends StatefulWidget {
  const Secondclasslist({super.key});

  @override
  State<Secondclasslist> createState() => _SecondclasslistState();
}

class _SecondclasslistState extends State<Secondclasslist> {
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
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Container(
              height: 150,
              width: double.infinity,
              //color: Colors.lightBlue,
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SmartSearchAttendance(),
                          ),
                        );

                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20)

                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Attendance", style:  TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                              SizedBox(width: 10,),
                              Lottie.asset("assets/attadance.json", height: 40),

                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Text("Test Reports", style:  TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),

                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(classes[index]['className']!),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                         GestureDetector(onTap :() {
                           Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (context) => SearchReports(classId: classes[index]['id']!),
                             ),
                           );


                         },child: Icon(Icons.save_as_rounded, color: Colors.blue,)),
                        ],
                      ),
                      onTap: () {


                      },
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
}
