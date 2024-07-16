import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

import '../Loginas.dart';
import '../Teachershatespeechview.dart';
import 'TeachersClassselection.dart';
class Teachersdashboard extends StatefulWidget {
  const Teachersdashboard({super.key});

  @override
  State<Teachersdashboard> createState() => _TeachersdashboardState();
}

class _TeachersdashboardState extends State<Teachersdashboard> {
  late String currentUserId = '';
  late String teacherName = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    getCurrentUserId();
  }

  void _openDrawer() {
    _scaffoldKey.currentState!.openDrawer(); // Change this line
  }

  Future<void> getCurrentUserId() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    if (user != null) {
      setState(() async {
        currentUserId = user.uid;
        FirebaseFirestore firestore = FirebaseFirestore.instance;
        DocumentSnapshot teacherSnapshot =
        await firestore.collection('Teachers').doc(currentUserId).get();

        if (teacherSnapshot.exists) {
          setState(() {
            teacherName = teacherSnapshot.get('Name');
          });
        }

      });

    }
  }

  Future<void> getTeacherName() async {

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
                    child: Lottie.asset("assets/teachers.json"),
                    decoration: BoxDecoration(
                      // color: Colors.white,
                      borderRadius: BorderRadius.circular(60), // Make it circular
                    ),
                  ),
                ),

              ),
              ListTile(
                title: Row(
                  children: [
                    Text('Logout', style: TextStyle(color: Colors.red),),
                    SizedBox(width: 10,),
                    Icon(Icons.login_sharp, color: Colors.red,)
                  ],
                ),
                onTap: () async {

                  await FirebaseAuth.instance.signOut();
                  // Navigate to the login page
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Selectin()),
                        (Route<dynamic> route) => false, // Clear the navigation stack
                  );
                },
              ),

              // Add more ListTile widgets for additional items
            ],
          ),
        ),
        backgroundColor: Colors.grey[100],
        body:SingleChildScrollView(
          child: Column(

            children: [
              // SizedBox(height: 10,),
              Container(
                width: double.infinity,

                child: Column(
                  children: [
                    Expanded(
                        flex: 5,child: Container(
                      // color: Colors.red,
                      child: Row(
                        children: [
                          Expanded(
                              child: Container(
                                //  color: Colors.red,
                                child:Padding(
                                  padding: const EdgeInsets.all(7.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,

                                    children: [

                                      Row(
                                        children: [
                                          GestureDetector(onTap: () {
                                            _openDrawer();
                                          },
                                            child: Icon(Icons.menu_open,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 10,),
                                          Text("Hello,", style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 25,
                                              fontWeight: FontWeight.bold

                                          ),),
                                        ],
                                      ),
                                      Text("$teacherName", style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold

                                      ),),

                                    ],
                                  ),
                                ),

                              )),
                          Expanded(
                              child: Container(
                                // color: Colors.yellow,
                                child: Center(
                                  child:  Lottie.asset('assets/teachers2.json'),
                                ),
                              )),
                        ],
                      ),
                    )),
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: Container(
                          // color: Colors.yellow,
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
                height: 220,


                decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(50),
                    )

                ),

              ),
              SizedBox(height: 10,),
              Container(
                child: Text("More Features", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 25),),
              ),

              Padding(
                padding: const EdgeInsets.all(3.0),
                child: Container(
                  width: double.infinity,
                  //height: 600,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child:Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            buildGridItem("Mark Attendance", context, "assets/attadance.json"),
                            SizedBox(height: 10,),
                            buildGridItem("Test Reports", context, "assets/paper.json"),
                            SizedBox(height: 10,),
                            buildGridItem("Hate Speech\nDetection", context, "assets/Hatespeech.json"),




                          ],
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

  Widget buildGridItem(String title, BuildContext context, String path) {
    return GestureDetector(
      onTap: () {
        if(title=="Mark Attendance"){
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) =>  Teachersclassselection(category: 'Mark Attendance',))
          );
        }else if((title=="Hate Speech\nDetection")) {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) =>  Hatespeechview())
          );
        }else if((title=="Fee Details")) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Feature Not Activated"),
                content: Text("You have not activated this feature yet."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        }else if((title=="Test Reports")) {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Teachersclassselection(category: 'Test Reports',))
          );
        }



      },
      child: Container(
        height: 180,
        width: 150,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            border: Border.all(color: Colors.deepPurple
            )// You can customize the color as needed
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Expanded(
              flex: 2,
              child: Container(
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
                flex: 8,
                child: Container(child: Lottie.asset(path))),
          ],


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
      color: isCurrentDate ? Colors.white : Colors.white, // Text color is white for both current and non-current dates
      fontWeight: isCurrentDate ? FontWeight.bold : FontWeight.normal,
    );

    BoxDecoration decoration = isCurrentDate
        ? BoxDecoration(
      color: Colors.blue, // Background color for current date
      borderRadius: BorderRadius.circular(10.0), // Rounded corners
    )
        : BoxDecoration(
      color: Colors.transparent, // Transparent background color for non-current dates
      borderRadius: BorderRadius.circular(10.0), // Rounded corners
    );

    return Container(
      decoration: decoration,
      padding: EdgeInsets.all(5.0), // Padding around the text
      child: Column(
        children: [
          SizedBox(height: 30,),
          Text(
            DateFormat.E().format(date), // Day of the week
            style: textStyle,
          ),
          SizedBox(height: 5), // Added some spacing between day and date
          Text(
            DateFormat.d().format(date), // Date
            style: textStyle,
          ),
        ],
      ),
    );
  }


}
