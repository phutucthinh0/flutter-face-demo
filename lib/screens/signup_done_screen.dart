import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:image/image.dart' as imageLib;

import '../data/firebase_database.dart';
import '../models/user.dart';
import '../utils/image_utils.dart';

class SignupDoneScreen extends StatefulWidget {
  final File file;
  final List predictedData;
  SignupDoneScreen({required this.file, required this.predictedData});

  @override
  _SignupDoneScreenState createState() => _SignupDoneScreenState();
}

class _SignupDoneScreenState extends State<SignupDoneScreen> {
  final tffNameController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initStateAsync();
  }
  void initStateAsync()async{
  }
  void done()async{
    User userToSave = User(
        user: tffNameController.text,
        modelData: widget.predictedData
    );
    // await db.saveUser(userToSave);
    FBRealtime.addUsers(userToSave);
    Get.back();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng kí gương mặt'),
      ),
      body:
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              width: 200,
              height: 200,
              margin: EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  image: DecorationImage(
                      image: FileImage(widget.file),
                    fit: BoxFit.contain
                  )
              ),
            ),
          ),
          Container(
            width: 300,
            child: TextFormField(
              controller: tffNameController,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: (){
              if(tffNameController.text.trim().isNotEmpty)
                done();
            },
            child: Text('Done'),
          )
        ],
      ),
    );
  }
}
