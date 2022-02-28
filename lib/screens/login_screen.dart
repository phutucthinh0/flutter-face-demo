import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_face_demo/services/face_anti_spoofing_serverice.dart';
import 'package:flutter_face_demo/services/face_verification_service.dart';
import 'package:flutter_face_demo/services/mask_detection_service.dart';
import 'package:flutter_face_demo/utils/image_utils.dart';
import 'package:flutter_face_demo/utils/scanner_utils.dart';
import 'package:get/get.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:sizer/sizer.dart';

import '../enums.dart';
import '../helpers/face_dectector_painter.dart';
import '../models/user.dart';
import '../widgets/face_scan.dart';
import 'hello.dart';
import 'package:image/image.dart' as imageLib;

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isInitialize = true;
  bool _isDetecting = false;
  bool _isSpoofing = false;
  bool _onPause = false;
  late List<CameraDescription> _cameras;
  late CameraController _cameraController;
  late CameraDescription _cameraDescription;
  late Size imageSize;
  late CameraImage _cameraImage;
  final FaceDetector _faceDetector = GoogleVision.instance.faceDetector(FaceDetectorOptions(enableContours: true));
  List<Face> _listFace = [];

  final MaskDetectionService _maskDetectionService = MaskDetectionService();
  final FaceAntiSpoofingService _faceAntiSpoofingService = FaceAntiSpoofingService();
  final FaceVerificationService _faceVerificationService = FaceVerificationService();

  int qualityScore = 0;
  String warningMsg = "";
  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  initStateAsync() async {
    await _maskDetectionService.initialize();
    await _faceAntiSpoofingService.initialize();
    // await _faceNetService.initialize();
    await _faceVerificationService.initialize();
    _cameras = await availableCameras();
    _cameraDescription = _cameras.firstWhere(
      (CameraDescription camera) =>
          camera.lensDirection == CameraLensDirection.front,
    );
    _cameraController = CameraController(
        _cameraDescription, ResolutionPreset.low,
        enableAudio: false);
    await _cameraController.initialize();
    ImageUtils.setImageRotation(_cameraDescription);
    imageSize = _cameraController.value.previewSize!;
    _cameraController.startImageStream(onLatestImageAvailable);
    setState(() {
      _isInitialize = false;
    });
  }

  void onLatestImageAvailable(CameraImage _cameraImage) async {
    if (_isDetecting || _onPause) return;
    this._cameraImage = _cameraImage;
    _isDetecting = true;
    dynamic results = await ScannerUtils.detect(image: _cameraImage, detectInImage: _faceDetector.processImage, imageRotation: _cameraDescription.sensorOrientation);
    setState(() {
      _listFace = results;
    });

    if(_listFace.length!=1){
      warningMsg = "Chỉ cần có 1 gương mặt";
      delayDetector();
      return;
    }
    var _maskState = _maskDetectionService.detectMask(ImageUtils.cropFace(_cameraImage, _listFace[0]));
    if(_maskState == MaskDetectorState.suspecting){
      delayDetector();
      return;
    }
    if(_maskState == MaskDetectorState.haveMask){
      warningMsg = "Vui lòng bỏ khẩu trang";
      delayDetector();
      return;
    }
    qualityScore = _faceAntiSpoofingService.laplacian(ImageUtils.cropFace(_cameraImage, _listFace[0]));
    // qualityScore = 902;
    if (qualityScore < 10){
      warningMsg = "Phát hiện giả mạo";
      delayDetector();
      return;
    }
    if (10 <= qualityScore && qualityScore <= 700) {
      warningMsg = "Vui lòng đưa lại gần\n hoặc làm sạch camera\n hoặc đưa ra khu vực đủ sáng";
      delayDetector();
      return;
    }
    if (qualityScore > 700) warningMsg = "ĐANG NHẬN DIỆN";
    // double score = await _faceAntiSpoofingService.antiSpoofing( ImageUtils.cropFace(_cameraImage, _listFace[0]));
    setState(() {
      qualityScore;
      warningMsg;
    });
    // delayDetector();
    // return;
    if (qualityScore > 700 && !_isSpoofing) {
      print('-----------------------');
      await _faceVerificationService.setCurrentPrediction(_cameraImage, _listFace[0]);
      User? _user = await _faceVerificationService.predict();
      if (_user != null) {
        _onPause = true;
        setState(() {
          _isInitialize = true;
        });
        if (await _faceAntiSpoofingService.antiSpoofing(ImageUtils.cropFace(_cameraImage, _listFace[0])) < 0.90) {
          warningMsg = "Giả mạo";
        } else {
          File _image = await ImageUtils.saveImage(ImageUtils.cropFace(_cameraImage, _listFace[0]));
          await Get.to(() => HelloScreen(user: _user, image: _image));
        }
        setState(() {
          _isInitialize = false;
        });
        _isDetecting = false;
        _onPause = false;
      } else {
        setState(() {
          warningMsg = "Null";
        });
      }
      // Future.delayed(Duration(seconds: 2), () {
      //   _isSpoofing = false;
      // });
      _isSpoofing = false;
    }
    delayDetector();
  }
  delayDetector(){
    Future.delayed(Duration(milliseconds: 1000), () => _isDetecting = false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quét khuôn mặt'),
      ),
      backgroundColor: Colors.blue,
      body: _isInitialize
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff2196F3)),
              ),
            )
          : Column(
            children: [
              Container(
                width: Get.width,
                height: Get.width * _cameraController.value.aspectRatio,
                child: Stack(
                  children: [
                    Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_cameraController),
                        // if(_listFace.isNotEmpty)
                        // CustomPaint(
                        //   painter: FaceDetectorPainter(
                        //       _listFace[0],
                        //       imageSize,
                        //       rotationIntToImageRotation(_cameraDescription.sensorOrientation)
                        //   ),
                        // ),
                      ],
                    ),
                    // Center(
                    //   child: Image.asset(
                    //     'assets/icons/round.png',
                    //     width: 200.sp,
                    //   ),
                    // ),
                    Center(
                      child: Image.asset("assets/icons/face_frame.png", width: 300,),
                    ),
                  ],
                ),
              ),
              Container(
                  margin: EdgeInsets.only(top: 50),
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Vui lòng đưa khuôn mặt vào trong khung\nvà giữ ổn định để nhận diện',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold),
                  )),
              Text('Quality score: $qualityScore'),
              // Text('Face: ${_listFace.length}'),
              Text(
                'Warning: $warningMsg',
                style: TextStyle(color: Colors.red),
              ),
              ElevatedButton(onPressed: (){
                _done();
              }, child: Text('aa'))
            ],
          ),
    );
  }
  _done()async{
    var img = ImageUtils.cropFace(_cameraImage,_listFace[0]);
    var file = await ImageUtils.saveImage(img);
    Get.to(HelloScreen(user: User(user: "test", modelData: []), image: file));
  }

  @override
  void dispose() {
    _faceDetector.close();
    _maskDetectionService.dispose();
    _faceVerificationService.dispose();
    // _faceNetService.dispose();
    _faceAntiSpoofingService.dispose();
    if (_cameraController.hasListeners) _cameraController.stopImageStream();
    super.dispose();
  }
}
