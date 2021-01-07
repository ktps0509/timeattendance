import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:intl/intl.dart';

class DetailAttendancePage extends StatefulWidget {
  final String id;

  DetailAttendancePage({Key key, this.id}) : super(key: key);

  @override
  _DetailAttendancePageState createState() {
    return _DetailAttendancePageState();
  }
}

class _DetailAttendancePageState extends State<DetailAttendancePage> {
  CollectionReference refTimeAttendance =
      FirebaseFirestore.instance.collection('timeattendance');

  List<QueryDocumentSnapshot> ref;

  @override
  void initState() {
    getData();
    super.initState();
  }

  void getData() async {
    QueryDocumentSnapshot refEmp;
    print(widget.id);
    await FirebaseFirestore.instance
        .collection("timeattendance")
        .where('employee_id', isEqualTo: widget.id)
        .get()
        .then((response) => {ref = response.documents});
    print('ref');
    print(ref.length);

    await FirebaseFirestore.instance
        .collection("employee")
        .where(FieldPath.documentId, isEqualTo: widget.id)
        .get()
        .then((response) => {refEmp = response.documents.first});

    print(refEmp);
    print(refEmp.get('FirstName'));
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(
          title: Text('TimeAttendance'),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection("timeattendance")
              .where('employee_id', isEqualTo: widget.id)
              .snapshots(),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return Center(child: CircularProgressIndicator());
              default:
                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: MakeListWidget(snapshot, context),
                );
            }
          },
        ));
  }

  List<Widget> MakeListWidget(AsyncSnapshot snapshot, BuildContext contex) {
    DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return snapshot.data.documents.map<Widget>((documents) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            height: MediaQuery.of(contex).size.height * 0.35,
            child: Card(
              child: Image.network(documents['imgpathIn']),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            height: MediaQuery.of(contex).size.height * 0.35,
            child: Text('CheckIn : ' +
                dateFormat
                    .format(DateTime.fromMillisecondsSinceEpoch(
                    documents['checkIn'].seconds * 1000))
                    .toString()),
          ),

        ],
      ); //          child: ListTile(
//              leading: CircleAvatar(
//                  backgroundImage: NetworkImage(documents['imgpathIn'])),
//          title: Text('CheckIn : ' +  dateFormat.format(DateTime.fromMillisecondsSinceEpoch(documents['checkIn'].seconds*1000)).toString()),)
//          );
    }).toList();
  }
}
