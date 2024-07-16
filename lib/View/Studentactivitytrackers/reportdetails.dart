import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportDetails extends StatefulWidget {
  final String reportId;

  const ReportDetails({Key? key, required this.reportId}) : super(key: key);

  @override
  _ReportDetailsState createState() => _ReportDetailsState();
}

class _ReportDetailsState extends State<ReportDetails> {
  Future<List<Map<String, dynamic>>> _fetchReportDetails() async {
    List<Map<String, dynamic>> reportDetails = [];

    try {
      DocumentSnapshot reportDoc = await FirebaseFirestore.instance.collection('TestReports').doc(widget.reportId).get();
      QuerySnapshot reportSubCollection = await reportDoc.reference.collection('Reports').get();

      for (var doc in reportSubCollection.docs) {
        var studentData = await FirebaseFirestore.instance.collection('Students').doc(doc.id).get();
        var studentName = studentData['StudentName'];
        reportDetails.add({
          'StudentId': doc.id,
          'StudentName': studentName,
          'ObtainedMarks': doc['ObtainedMarks'],
          'TotalMarks': reportDoc['TotalMarks']
        });
      }
    } catch (e) {
      print("Error fetching report details: $e");
    }

    return reportDetails;
  }

  Future<void> _editMarks(String studentId, int currentMarks) async {
    final TextEditingController marksController = TextEditingController(text: currentMarks.toString());
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Marks'),
          content: TextField(
            controller: marksController,
            decoration: InputDecoration(labelText: 'Enter new marks'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                int? newMarks = int.tryParse(marksController.text);
                if (newMarks != null) {
                  await FirebaseFirestore.instance
                      .collection('TestReports')
                      .doc(widget.reportId)
                      .collection('Reports')
                      .doc(studentId)
                      .update({'ObtainedMarks': newMarks});
                  Navigator.of(context).pop();
                  setState(() {});  // Refresh the UI to show updated marks
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter valid marks')));
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Details'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchReportDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No details found'));
          } else {
            var reportDetails = snapshot.data!;
            return ListView.builder(
              itemCount: reportDetails.length,
              itemBuilder: (context, index) {
                var student = reportDetails[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(20)),

                    ),
                    child: ListTile(
                      title: Text(student['StudentName']),
                      subtitle: Text('Marks: ${student['ObtainedMarks']} / ${student['TotalMarks']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.green,),
                        onPressed: () => _editMarks(student['StudentId'], student['ObtainedMarks']),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
