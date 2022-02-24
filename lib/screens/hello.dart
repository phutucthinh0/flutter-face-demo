import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../models/user.dart';

class HelloScreen extends StatefulWidget {
  final User user;
  final File image;

  const HelloScreen({Key? key, required this.user, required this.image})
      : super(key: key);

  @override
  _HelloScreenState createState() => _HelloScreenState();
}

class _HelloScreenState extends State<HelloScreen> {
  bool _acceptBack = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      Get.back();
      setState(() {
        _acceptBack = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nhận diện thành công!'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (_acceptBack) Get.back();
          },
        ),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Color(0xff2196F3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20,),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.file(
                  widget.image,
                  fit: BoxFit.cover,
                  width: 150,
                  height: 150,
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10.sp),
                alignment: Alignment.center,
                child: Text(
                  'Xin chào ${widget.user.user}',
                  style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
}
