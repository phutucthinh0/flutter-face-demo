import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_face_demo/data/firebase_database.dart';
import 'package:flutter_face_demo/data/local_database.dart';
import 'package:flutter_face_demo/screens/login_screen.dart';
import 'package:flutter_face_demo/screens/signup_screen.dart';
import 'package:flutter_face_demo/widgets/opacity_button.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime now = DateTime.now();
  Timer? _timer;
  // String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

  @override
  void initState() {
    localDatabase.initialize();
    FBRealtime.initialize();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        now = DateTime.now();
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(now.day);
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Color(0xff0B4DE4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: EdgeInsets.only(top: 20),
                child: TouchableOpacity(
                  onTap: () => Get.to(() => SignupScreen()),
                  child: Image.asset(
                    'assets/icons/ic_admin.png',
                    width: 30.sp,
                  ),
                ),
              ),
              Column(
                children: [
                  Image.asset(
                    'assets/icons/faceid3.png',
                    width: 130.sp,
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Container(
                      margin: EdgeInsets.only(left: 20, right: 20),
                      child: Text(
                        'Ứng dụng điểm danh',
                        style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            wordSpacing: 1,
                            color: Color(0xffffffff)),
                      )),
                  Container(
                      margin: EdgeInsets.only(left: 20, right: 20),
                      child: Text(
                        'bằng khuôn mặt',
                        style: TextStyle(
                            fontSize: 15.sp,
                            wordSpacing: 1,
                            fontWeight: FontWeight.w600,
                            color: Color(0xffffffff)),
                      )),
                ],
              ),
              Column(
                children: [
                  TouchableOpacity(
                    onTap: () => Get.to(() => LoginScreen()),
                    child: Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 40.sp, vertical: 30),
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xff2FC7D3).withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: Offset(
                                0,
                                7,
                              ), // changes position of shadow
                            ),
                          ],
                          // border: Border.all(color: Colors.white, width: 0),
                          color: Color(0xff2FC7D3)),
                      height: 50,
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Chạm để điểm danh',
                            style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff1C2D48)),
                          ),
                          SizedBox(
                            width: 10.sp,
                          ),
                          Image.asset(
                            'assets/icons/click.png',
                            width: 20.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(right: 40.sp),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        DateFormat('HH:mm:ss').format(now),
                        style: TextStyle(
                            fontSize: 25.sp,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff55DBFF)),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 5.sp,
                  ),
                  Container(
                    margin: EdgeInsets.only(right: 40.sp),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(now),
                        style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 30.sp,
                  )
                ],
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
    _timer!.cancel();
  }
}
