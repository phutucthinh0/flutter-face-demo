import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/user.dart';

class HelloScreen extends StatefulWidget {
  final User user;

  const HelloScreen({Key? key, required this.user}) : super(key: key);

  @override
  _HelloScreenState createState() => _HelloScreenState();
}

class _HelloScreenState extends State<HelloScreen> {
  bool _acceptBack = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(seconds: 3),(){
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
        title: Text('Xin chào'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: (){
            if(_acceptBack)Get.back();
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: Text('Xin chào ${widget.user.user}'),),
          Spacer(),
        ],
      ),
    );
  }
}
