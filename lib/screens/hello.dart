import 'package:flutter/material.dart';

import '../models/user.dart';

class HelloScreen extends StatefulWidget {
  final User user;

  const HelloScreen({Key? key, required this.user}) : super(key: key);

  @override
  _HelloScreenState createState() => _HelloScreenState();
}

class _HelloScreenState extends State<HelloScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Xin chào'),
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
