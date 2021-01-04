import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:timeattendance/model/timeattendance.dart';
import 'package:timeattendance/services/attendanceService.dart';

class TimeAttendancePage extends StatefulWidget {
  final CameraDescription camera;
  final String id;

  TimeAttendancePage({Key key, @required this.camera, this.id})
      : super(key: key);

  // @override
  // _TimeAttendancePageState createState() => _TimeAttendancePageState();
// State<StatefulWidget> createState() {
//   return _TimeAttendancePageState();
// }
  @override
  _TimeAttendancePageState createState() {
    return _TimeAttendancePageState();
  }
}

class _TimeAttendancePageState extends State<TimeAttendancePage>
    with WidgetsBindingObserver {
  CameraController controller;
  Future<void> _initializeControllerFuture;
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final databaseReference = Firestore.instance;
  String imgPath;

  DateTime _datetimeNow;
  TextEditingController _employeeIDController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  bool _toggleCamera = false;

  CollectionReference refTimeAttendance =
      FirebaseFirestore.instance.collection('timeattendance');

  // @override
  // void initState() {
  //   try {
  //     print(widget.id);
  //     if (widget.id == null) {
  //       Navigator.pop(context);
  //     }
  //   } catch (e) {
  //     print(e.toString());
  //   }
  //   super.initState();
  //   _datetimeNow = DateTime.now();
  // }

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      widget.camera,
      ResolutionPreset.ultraHigh,
    );

    _initializeControllerFuture = controller.initialize();

    print('controller');
    print(controller);
    _datetimeNow = DateTime.now();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
    }
  }

  //
  // @override
  // void dispose() {
  //   super.dispose();
  // }

  void showException(CameraException e) {
    logError(e.code, e.description);
    showMessage('Error: ${e.code}\n${e.description}');
  }

  void showMessage(String message) {
    print(message);
    // Navigator.of(context).pop(null);
  }

  void logError(String code, String message) {
    print('Error: $code\nMessage: $message');
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    // controller = CameraController(
    //   cameraDescription,
    //   ResolutionPreset.medium,
    //   enableAudio: true,
    // );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        _showSnackbar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
      // _maxAvailableZoom = await controller.getMaxZoomLevel();
      // _minAvailableZoom = await controller.getMinZoomLevel();
    } on CameraException catch (e) {
      showException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<String> takePicture() async {
    String timestamp() => new DateTime.now().millisecondsSinceEpoch.toString();
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/FlutterDevs/Camera/Images';
    await new Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (!controller.value.isInitialized) {
      _showSnackbar('Error: select a camera first.');
      return null;
    }

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      print('aaaaa');
      await controller.takePicture(filePath);
      return filePath;
    } on CameraException catch (e) {
      showException(e);
      return null;
    }
  }

  void _checkIn() async {
    List<QueryDocumentSnapshot> ref;
    DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    DateFormat dateFormatImg = DateFormat('ddMMyyyy');
    String ImgUrlIn;

    await takePicture().then((String file) {
      if (mounted) {
        setState(() {
          imgPath = file;
        });
        if (file != null) _showSnackbar('Picture saved to ${file}');
      }
    });

    // Create a Reference to the file
    firebase_storage.Reference refstore = FirebaseStorage.instance
        .ref()
        .child('facescan')
        .child(widget.id)
        .child(dateFormatImg.format(_datetimeNow).toString() + '_checkIn');
    firebase_storage.UploadTask uploadTask = refstore.putFile(File(imgPath));
    firebase_storage.TaskSnapshot taskSnapshot =
        await uploadTask.whenComplete(() => print('Complete'));
    print('File Uploaded');
    await refstore.getDownloadURL().then((fileURL) => {
          setState(() {
            ImgUrlIn = fileURL;
          })
        });

    print('fileURL');
    print(ImgUrlIn);

    await FirebaseFirestore.instance
        .collection("timeattendance")
        .where('employee_id', isEqualTo: widget.id)
        .where('activeFlag', isEqualTo: true)
        .where('date', isEqualTo: dateFormat.format(_datetimeNow).toString())
        .get()
        .then((response) => {ref = response.documents});

    _showSnackbar("กำลังบันทึก");

    print('ref.documents');
    print(ref);
    if (ref.length <= 0) {
      DocumentReference ref = await refTimeAttendance.add({
        'employee_id': widget.id,
        'checkIn': _datetimeNow,
        'checkOut': null,
        'activeFlag': true,
        'imgpathIn': ImgUrlIn,
        'imgpathOut': '',
        'date': dateFormat.format(_datetimeNow).toString()
      });

      if (ref.documentID != null) {
        _showSnackbar("บันทึกสำเร็จ");
        Navigator.pop(context);
      } else {
        _showSnackbar("Error!");
      }
    }
  }

  void _checkOut() async {
    QueryDocumentSnapshot ref;
    DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    DateFormat dateFormatImg = DateFormat('ddMMyyyy');
    String ImgUrlOut;

    await takePicture().then((String file) {
      if (mounted) {
        setState(() {
          imgPath = file;
        });
        if (file != null) _showSnackbar('Picture saved to ${file}');
      }
    });

    // Create a Reference to the file
    firebase_storage.Reference refstore = FirebaseStorage.instance
        .ref()
        .child('facescan')
        .child(widget.id)
        .child(dateFormatImg.format(_datetimeNow).toString() + '_checkOut');
    firebase_storage.UploadTask uploadTask = refstore.putFile(File(imgPath));
    firebase_storage.TaskSnapshot taskSnapshot =
        await uploadTask.whenComplete(() => print('Complete'));
    print('File Uploaded');
    await refstore.getDownloadURL().then((fileURL) => {
          setState(() {
            ImgUrlOut = fileURL;
          })
        });

    await FirebaseFirestore.instance
        .collection("timeattendance")
        .where('employee_id', isEqualTo: widget.id)
        .where('checkIn', isNotEqualTo: null)
        .where('activeFlag', isEqualTo: true)
        .where('date', isEqualTo: dateFormat.format(_datetimeNow).toString())
        .get()
        .then((response) => {ref = response.documents.last});
    print('checkOut');
    print(ref.documentID);
    if (ref != null) {
      await refTimeAttendance
          .doc(ref.documentID)
          .update({
            'checkOut': _datetimeNow,
            'imgpathOut': ImgUrlOut,
            'activeFlag': false,
          })
          .then((value) =>
              {_showSnackbar("บันทึกสำเร็จ"), Navigator.pop(context)})
          .catchError((error) => _showSnackbar("เกิดข้อผิดพลาด"));
    }
  }

  _showSnackbar(String message) {
    final snackBar = SnackBar(content: Text(message));
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size.width;

    return Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomPadding: false,
        appBar: AppBar(
          title: Text('TimeAttendance'),
          centerTitle: true,
          backgroundColor: Colors.deepOrangeAccent,
        ),
        body: Container(
          height: double.infinity,
          width: double.infinity,
          // color: Colors.black,
          child: Transform.scale(
            scale: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Container(
                width: size,
                height: size * 1.5,
                child: Stack(
                  children: <Widget>[
                    FutureBuilder(
                        future: _initializeControllerFuture,
                        builder: (context, snapshot) =>
                            CameraPreview(controller)),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(50, 0, 50, 30),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: SizedBox(
                                height: 55,
                                width: 145,
                                child: RaisedButton(
                                  onPressed: _checkIn,
                                  color: Colors.lightGreen,
                                  child: Text(
                                    "Check In",
                                    style: TextStyle(fontSize: 22),
                                  ),
                                  textColor: Colors.white,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: SizedBox(
                                height: 55,
                                width: 145,
                                child: RaisedButton(
                                  onPressed: _checkOut,
                                  color: Colors.deepOrangeAccent,
                                  child: Text("Check Out",
                                      style: TextStyle(fontSize: 22)),
                                  textColor: Colors.white,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
