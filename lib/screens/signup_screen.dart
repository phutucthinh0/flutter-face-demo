import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_face_demo/screens/signup_done_screen.dart';
import 'package:flutter_face_demo/services/face_verification_service.dart';
import 'package:flutter_face_demo/utils/face_utils.dart';
import 'package:get/get.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import '../enums.dart';
import '../helpers/face_dectector_painter.dart';
import '../utils/image_utils.dart';
import '../utils/scanner_utils.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _isInitialize = true;
  bool _isDetecting = false;
  bool _isFaceTrue = false;
  bool _isSuccess = false;
  bool _showDebug = false;
  late List<CameraDescription> _cameras;
  late CameraController _cameraController;
  late CameraDescription _cameraDescription;
  late Size imageSize;
  final FaceDetector _faceDetector = GoogleVision.instance.faceDetector(const FaceDetectorOptions(enableContours: true));
  List<Face> _listFace = [];
  final FaceVerificationService _faceVerificationService = FaceVerificationService();
  String cautionMsg = "";
  late CameraImage cameraImage;
  Timer? _timer;
  final List _listModeldata = [];
  final List<File> _listFileFace = [];
  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  initStateAsync() async {
    await _faceVerificationService.initialize();
    _cameras = await availableCameras();
    _cameraDescription = _cameras.firstWhere(
      (CameraDescription camera) =>
          camera.lensDirection == CameraLensDirection.front,
    );
    _cameraController = CameraController(_cameraDescription, ResolutionPreset.max, enableAudio: false);
    await _cameraController.initialize();
    ImageUtils.setImageRotation(_cameraDescription);
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
    dynamic results = await ScannerUtils.detect(
        image: _cameraImage,
        detectInImage: _faceDetector.processImage,
        imageRotation: _cameraDescription.sensorOrientation);
    setState(() {
      _listFace = results;
    });
    if (_listFace.length == 1) {
      onSignup();
    } else {
      if (_timer != null) _timer!.cancel();
      if (_listFace.isEmpty) {
        cautionMsg = "Vui lòng đưa gương mặt vào chính giữa";
      } else {
        cautionMsg = "Quá nhiều gương mặt";
      }
    }
    delayDetector();
  }
  delayDetector() {
    Future.delayed(Duration(milliseconds: 10), () => _isDetecting = false);
  }
  void onSignup() async {
    if (_isSuccess) return;
    if (_listModeldata.length >= 3) {
      _isSuccess = true;
      cautionMsg = "Hoàn tất đăng kí, đợi trong giây lát";
      Future.delayed(const Duration(seconds: 2), () {
        Get.off(() => SignupDoneScreen(
            file: _listFileFace[0], listModelData: _listModeldata));
      });
      return;
    }
    if (_timer != null) {
      FaceUtils _faceUtils = FaceUtils(_listFace[0], Get.width/imageSize.width);
      List<Offset> _listPoint = _listFace[0].getContour(FaceContourType.face)!.positionsList;
      double distance = (_listPoint[9].dx -  _listPoint[28].dx)*(Get.width/imageSize.width);
      if (_faceUtils.isStraight()) {
        cautionMsg = "Vui lòng nhìn thẳng";
        _isFaceTrue = false;
        _timer!.cancel();
        _timer = null;
        return;
      }
      switch (_listModeldata.length) {
        case 0:{
          final state = _faceUtils.isScaleLevel1();
          if(state == FaceScaleState.tooFar){
            cautionMsg = "Vui lòng lại gần hơn";
            _isFaceTrue = false;
            _timer!.cancel();
            _timer = null;
          }
          if(state == FaceScaleState.tooClose){
            cautionMsg = "Vui lòng lại đưa ra xa";
            _isFaceTrue = false;
            _timer!.cancel();
            _timer = null;
          }
          if(state == FaceScaleState.normal){
            cautionMsg = "Giữ yên";
            _isFaceTrue = true;
          }
          break;
        }
        case 1:{
          final state = _faceUtils.isScaleLevel2();
          if(state == FaceScaleState.tooFar){
            cautionMsg = "Vui lòng lại gần hơn";
            _isFaceTrue = false;
            _timer!.cancel();
            _timer = null;
          }
          if(state == FaceScaleState.tooClose){
            cautionMsg = "Vui lòng lại đưa ra xa";
            _isFaceTrue = false;
            _timer!.cancel();
            _timer = null;
          }
          if(state == FaceScaleState.normal){
            cautionMsg = "Giữ yên";
            _isFaceTrue = true;
          }
          break;
        }
        case 2:{
          final state = _faceUtils.isScaleLevel3();
          if(state == FaceScaleState.tooFar){
            cautionMsg = "Vui lòng lại gần hơn";
            _isFaceTrue = false;
            _timer!.cancel();
            _timer = null;
          }
          if(state == FaceScaleState.tooClose){
            cautionMsg = "Vui lòng lại đưa ra xa";
            _isFaceTrue = false;
            _timer!.cancel();
            _timer = null;
          }
          if(state == FaceScaleState.normal){
            cautionMsg = "Giữ yên";
            _isFaceTrue = true;
          }
          break;
        }
      }
      return;
    }
    _timer = Timer(const Duration(milliseconds: 2000), () async {
      final CameraImage _img = cameraImage;
      final Face _face = _listFace[0];
      setState(() {
        _listModeldata.add(_faceVerificationService.setCurrentPrediction(_img, _face));
      });
      if(_listModeldata.length == 3){
        File file = await ImageUtils.saveImage(ImageUtils.cropFace(_img, _face));
        _listFileFace.add(file);
      }
      _timer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
      ),
      body: _isInitialize
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff2196F3)),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  width: Get.width,
                  height: Get.height-200,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: Get.width,
                      height: Get.width * _cameraController.value.aspectRatio,
                      child: Stack(
                        children: [
                          Stack(
                            fit: StackFit.expand,
                            children: [
                              CameraPreview(_cameraController),
                              if(_listFace.isNotEmpty)
                                CustomPaint(
                                  painter: FaceDetectorPainter(
                                      _listFace[0],
                                      imageSize,
                                      rotationIntToImageRotation(_cameraDescription.sensorOrientation),
                                      _isFaceTrue?Colors.green:Colors.red
                                  ),
                                ),
                            ],
                          ),
                          Center(
                            child: Container(
                              width: 350,
                              height: 410,
                              decoration: BoxDecoration(
                                  border: Border.all(color: _isFaceTrue? Colors.green:Colors.red, width: 4)),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: 348,
                                  height: 60,
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                      color: Colors.black87),
                                  child: Center(
                                      child: Text(cautionMsg,
                                          style: const TextStyle(color: Colors.white))),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('${_listModeldata.length}/3', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.blue),),
              ],
            ),
    );
  }

  @override
  void dispose() {
    if (_cameraController.hasListeners) _cameraController.stopImageStream();
    _faceDetector.close();
    _faceVerificationService.dispose();
    if (_timer != null) _timer!.cancel();
    super.dispose();
  }
}
