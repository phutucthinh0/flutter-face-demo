
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_face_demo/enums.dart';
import 'package:flutter_face_demo/screens/signup_done_screen.dart';
import 'package:flutter_face_demo/services/face_verification_service.dart';
import 'package:get/get.dart';
import 'package:google_ml_vision/google_ml_vision.dart';

import '../helpers/face_dectector_painter.dart';
import '../services/face_anti_spoofing_serverice.dart';
import '../utils/image_utils.dart';
import '../utils/scanner_utils.dart';

import 'package:image/image.dart' as imageLib;

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _isInitialize = true;
  bool _isDetecting = false;
  bool _isSpoofing = false;
  late List<CameraDescription> _cameras;
  late CameraController _cameraController;
  late CameraDescription _cameraDescription;
  late Size imageSize;
  final FaceDetector _faceDetector = GoogleVision.instance.faceDetector(FaceDetectorOptions(enableContours: true));
  List<Face> _listFace = [];

  final FaceAntiSpoofingService _faceAntiSpoofingService = FaceAntiSpoofingService();
  final FaceVerificationService _faceVerificationService = FaceVerificationService();
  int qualityScore = 0;
  String warningMsg = "";
  late CameraImage cameraImage;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initStateAsync();
  }

  initStateAsync() async {
    await _faceAntiSpoofingService.initialize();
    await _faceVerificationService.initialize();
    _cameras = await availableCameras();
    _cameraDescription = _cameras.firstWhere(
      (CameraDescription camera) => camera.lensDirection == CameraLensDirection.front,
    );
    _cameraController = CameraController(_cameraDescription, ResolutionPreset.medium, enableAudio: false);
    await _cameraController.initialize();
    ImageUtils.imageRotation = _cameraDescription.sensorOrientation;
    imageSize = _cameraController.value.previewSize!;
    _cameraController.startImageStream(onLatestImageAvailable);
    setState(() {
      _isInitialize = false;
    });
  }

  void onLatestImageAvailable(CameraImage _cameraImage) async {
    if (_isDetecting) return;
    cameraImage = _cameraImage;
    _isDetecting = true;
    ScannerUtils.detect(image: _cameraImage, detectInImage: _faceDetector.processImage, imageRotation: _cameraDescription.sensorOrientation).then((dynamic results) async {
      if (results is List<Face>) {
        setState(() {
          _listFace = results;
        });
        if (_listFace.length == 1) {
          qualityScore = _faceAntiSpoofingService.laplacian(ImageUtils.cropFace(_cameraImage, _listFace[0]));
          if (qualityScore <= 500) warningMsg = "Vui lòng đưa lại gần\n hoặc làm sạch camera\n hoặc đưa ra khu vực đủ sáng";
          if (qualityScore > 500) warningMsg = "CÓ THỂ ĐĂNG KÍ";
          setState(() {
            qualityScore;
            warningMsg;
          });
        } else {
          qualityScore = 0;
          warningMsg = "Chỉ được có 1 gương mặt";
        }
      }
    }).whenComplete(() => Future.delayed(Duration(milliseconds: 100), () => _isDetecting = false));
  }

  void onSignup() async {
    if (_listFace.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('Không tìm thấy gương mặt'),
          );
        },
      );
      return;
    }
    if (_listFace.length > 1) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('Quá nhiều gương mặt'),
          );
        },
      );
      return;
    }
    if(qualityScore<500){
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text(warningMsg),
          );
        },
      );
      return;
    }
    _cameraController.stopImageStream();
    imageLib.Image imgFace = ImageUtils.cropFace(cameraImage, _listFace[0]);
    List predictedData = _faceVerificationService.setCurrentPrediction(cameraImage, _listFace[0]);
    File file = await ImageUtils.saveImage(imgFace);
    Get.off(()=>SignupDoneScreen(file: file, predictedData: predictedData));
    // await Get.to(()=>SignupScreen(cameraImage: cameraImage,face: faceDetected,));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng ký'),
      ),
      body: _isInitialize
          ? Center(child: Text('Initialize'))
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
                          if (_listFace.isNotEmpty)
                            CustomPaint(
                              painter: FaceDetectorPainter(_listFace[0], imageSize, rotationIntToImageRotation(_cameraDescription.sensorOrientation)),
                            ),
                        ],
                      ),
                      Center(
                        child: Container(
                          width: 350,
                          height: 350,
                          decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 2)),
                        ),
                      )
                    ],
                  ),
                ),
                Text('Quality score: $qualityScore'),
                Text('Face: ${_listFace.length}'),
                Text(
                  'Warning: $warningMsg',
                  style: TextStyle(color: Colors.red),
                ),
                ElevatedButton(onPressed: ()=>onSignup(), child: Text('DONE')),
              ],
            ),
    );
  }
  @override
  void dispose() {
    if(_cameraController.hasListeners) _cameraController.stopImageStream();
    _faceDetector.close();
    _faceVerificationService.dispose();
    _faceAntiSpoofingService.dispose();
    super.dispose();
  }
}
