import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeattendance/pages/TimeAttendance.dart';

class ListTimeAttendancePage extends StatelessWidget {
  List<Widget> MakeListWidget(AsyncSnapshot snapshot, BuildContext context) {
    return snapshot.data.documents.map<Widget>((documents) {
      return Card(
          child: ListTile(
        leading: CircleAvatar(
            backgroundImage: NetworkImage(documents['ImgProfile'])),
        title: Text(documents['FirstName'] + " " + documents['LastName']),
        subtitle: Text("Position : " + documents['Position']),
        onTap: () async {
          WidgetsFlutterBinding.ensureInitialized();
          // Obtain a list of the available cameras on the device.
          final cameras = await availableCameras();
          final firstCamera = cameras.first;

          print('firstCamera');
          print(firstCamera);
          // Navigator.of(context).push(_createRoute(firstCamera, documents.reference.documentID.toString()));

          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TimeAttendancePage(
                    camera: firstCamera,
                    id: documents.reference.documentID.toString())),
          );
        },
      ));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("TimeAttendance"),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: Container(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection("employee")
              .orderBy('Position')
              .snapshots(),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return Center(child: CircularProgressIndicator());
              default:
                return ListView(
                  children: MakeListWidget(snapshot, context),
                );
            }
          },
        ),
      ),
    );
  }

  Route _createRoute(firstCamera, id) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          TimeAttendancePage(camera: firstCamera, id: id),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }
}
