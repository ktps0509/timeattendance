import 'dart:convert' as convert;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:timeattendance/model/timeattendance.dart';

class TimeAttendanceService {

  static const STATUS_SUCCESS = "SUCCESS";

  static void CheckIn(
      TimeAttendance time_attendance, void Function(String) callback) async {
    await Firebase.initializeApp();
    var firebase = FirebaseFirestore.instance.collection('timeattendanceee')
        .snapshots();
    print(firebase);


    Future<DocumentSnapshot> getData() async {
      await Firebase.initializeApp();
      return await FirebaseFirestore.instance
          .collection("users")
          .doc("docID")
          .get();
    }
  }
}
