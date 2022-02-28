import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class DialogFaceFake extends StatefulWidget {
  const DialogFaceFake({Key? key}) : super(key: key);

  @override
  _DialogFaceFakeState createState() => _DialogFaceFakeState();
}

class _DialogFaceFakeState extends State<DialogFaceFake> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.w,
      padding: EdgeInsets.symmetric(vertical: 40.sp),
      decoration: BoxDecoration(
        color: Colors.yellow,
        borderRadius: BorderRadius.circular(10.sp),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Phát hiện khuôn mặt giả mạo',
            style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          )
        ],
      ),
    );
  }
}
