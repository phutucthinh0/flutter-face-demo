import 'package:flutter/material.dart';
import 'package:flutter_face_demo/data/firebase_database.dart';
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
  // String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

  @override
  void initState() {
    FBRealtime.initialize();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(now);
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Color(0xff2196F3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: EdgeInsets.only(top: 20),
                child: TouchableOpacity(
                  onTap: () => Get.to(()=>SignupScreen()),
                  child: Image.asset(
                    'assets/icons/ic_admin.png',
                    width: 50,
                  ),
                ),
              ),
              Column(
                children: [
                  Image.asset(
                    'assets/icons/face.png',
                    width: 300,
                  ),
                  Container(
                      margin: EdgeInsets.only(left: 20, right: 20),
                      child: Text(
                        'Ứng dụng điểm danh',
                        style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Color(0xffffffff)),
                      )),
                  Container(
                      margin: EdgeInsets.only(left: 20, right: 20),
                      child: Text(
                        'bằng khuôn mặt',
                        style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Color(0xffffffff)),
                      )),
                ],
              ),
              Column(
                children: [
                  TouchableOpacity(
                    onTap: ()=> Get.to(()=>LoginScreen()),
                    child: Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 30),
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
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
                          border: Border.all(color: Colors.white, width: 0),
                          color: Color(0xff2FC7D3)),
                      height: 45,
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Chạm để điểm danh',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Image.asset(
                            'assets/icons/click.png',
                            width: 30,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
