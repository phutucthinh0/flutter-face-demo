import 'package:flutter/material.dart';
import 'package:flutter_face_demo/data/firebase_database.dart';
import 'package:flutter_face_demo/screens/login_screen.dart';
import 'package:flutter_face_demo/screens/signup_screen.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    FBRealtime.initialize();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => Get.to(()=>SignupScreen()),
            child: Text('Đăng kí'),
          ),
          ElevatedButton(
            onPressed: ()=> Get.to(()=>LoginScreen()),
            child: Text('Đăng nhập'),
          )
        ],
      ),
    );
  }
}
