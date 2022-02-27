import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_face_demo/screens/signup_done_screen.dart';
import 'package:flutter_face_demo/services/face_verification_service.dart';
import 'package:get/get.dart';
import 'package:google_ml_vision/google_ml_vision.dart';

import '../services/face_anti_spoofing_serverice.dart';
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
  bool _isSucess = false;
  late List<CameraDescription> _cameras;
  late CameraController _cameraController;
  late CameraDescription _cameraDescription;
  late Size imageSize;
  final FaceDetector _faceDetector = GoogleVision.instance.faceDetector(const FaceDetectorOptions(enableContours: true));
  List<Face> _listFace = [];
  final FaceAntiSpoofingService _faceAntiSpoofingService = FaceAntiSpoofingService();
  final FaceVerificationService _faceVerificationService = FaceVerificationService();
  int qualityScore = 0;
  String warningMsg = "";
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
    await _faceAntiSpoofingService.initialize();
    await _faceVerificationService.initialize();
    _cameras = await availableCameras();
    _cameraDescription = _cameras.firstWhere(
      (CameraDescription camera) =>
          camera.lensDirection == CameraLensDirection.front,
    );
    _cameraController = CameraController(_cameraDescription, ResolutionPreset.low, enableAudio: false);
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
    ScannerUtils.detect(
            image: _cameraImage,
            detectInImage: _faceDetector.processImage,
            imageRotation: _cameraDescription.sensorOrientation)
        .then((dynamic results) async {
      if (results is List<Face>) {
        setState(() {
          _listFace = results;
        });
        if (_listFace.length == 1) {
          qualityScore = _faceAntiSpoofingService
              .laplacian(ImageUtils.cropFace(_cameraImage, _listFace[0]));
          if (qualityScore <= 500) {
            warningMsg = "Vui lòng đưa lại gần hoặc làm sạch camera hoặc đưa ra khu vực đủ sáng";
          }
          if (qualityScore > 500) {
            onSignup();
          }
          setState(() {
            qualityScore;
            warningMsg;
          });
        } else {
          if (_timer != null) _timer!.cancel();
          qualityScore = 0;
          if (_listFace.isEmpty) {
            warningMsg = "Vui lòng đưa gương mặt vào chính giữa";
          } else {
            warningMsg = "Chỉ được có 1 gương mặt";
          }
        }
      }
      Future.delayed(const Duration(milliseconds: 100), () => _isDetecting = false);
    });
  }

  void onSignup() async {
    if (_isSucess) return;
    if (_listModeldata.length >= 3) {
      _isSucess = true;
      warningMsg = "Hoàn tất đăng kí, đợi trong giây lát";
      Future.delayed(const Duration(seconds: 2), () {
        Get.off(() => SignupDoneScreen(
            file: _listFileFace[0], listModelData: _listModeldata));
      });
      return;
    }
    if (_timer != null) {
      List<Offset> _listPoint = _listFace[0].getContour(FaceContourType.noseBottom)!.positionsList;
      double leftPoint = _listPoint[1].dx - _listPoint[0].dx;
      double rightPoint = _listPoint[2].dx - _listPoint[1].dx;
      switch (_listModeldata.length) {
        case 0:
          {
            if ((leftPoint - rightPoint).abs() > 2) {
              warningMsg = "Vui lòng nhìn thẳng";
              _timer!.cancel();
              _timer = null;
            } else {
              warningMsg = "Tiếp giữ gương mặt nhìn thẳng";
            }
            break;
          }
        case 1:
          {
            if (leftPoint - rightPoint < 4) {
              warningMsg = "Vui lòng nhìn sang Trái";
              _timer!.cancel();
              _timer = null;
            } else {
              warningMsg = "Tiếp tục nhìn sang Trái";
            }
            break;
          }
        case 2:
          {
            if (rightPoint - leftPoint < 4) {
              warningMsg = "Vui lòng nhìn sang Phải";
              _timer!.cancel();
              _timer = null;
            } else {
              warningMsg = "Tiếp tục nhìn sang Phải";
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
        _listModeldata
            .add(_faceVerificationService.setCurrentPrediction(_img, _face));
      });
      _listFileFace
          .add(await ImageUtils.saveImage(ImageUtils.cropFace(_img, _face)));
      _timer = null;
    });
    // _cameraController.stopImageStream();
    // imageLib.Image imgFace = ImageUtils.cropFace(cameraImage, _listFace[0]);
    // List predictedData = _faceVerificationService.setCurrentPrediction(cameraImage, _listFace[0]);
    // File file = await ImageUtils.saveImage(imgFace);
    // Get.off(()=>SignupDoneScreen(file: file, predictedData: predictedData));
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
                  height: Get.width * _cameraController.value.aspectRatio,
                  child: Stack(
                    children: [
                      Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(_cameraController),
                          // if (_listFace.isNotEmpty)
                          //   CustomPaint(
                          //     painter: FaceDetectorPainter(_listFace[0], imageSize, rotationIntToImageRotation(_cameraDescription.sensorOrientation)),
                          //   ),
                        ],
                      ),
                      Center(
                        child: Image.asset("assets/icons/face_frame.png", width: 300,),
                      ),
                      Center(
                        child: Container(
                          width: 350,
                          height: 410,
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue, width: 2)),
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
                                  child: Text(warningMsg,
                                      style: const TextStyle(color: Colors.white))),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: _listFileFace.length >= 2 ? 1 : 0,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(color: Colors.white),
                        child: _listFileFace.length >= 2
                            ? Image.file(
                                _listFileFace[1],
                                fit: BoxFit.cover,
                              )
                            : Container(),
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: _listFileFace.isNotEmpty ? 1 : 0,
                      child: Container(
                        width: 102,
                        height: 102,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: _listFileFace.isNotEmpty
                            ? Image.file(
                                _listFileFace[0],
                                fit: BoxFit.cover,
                              )
                            : Container(),
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: _listFileFace.length >= 3 ? 1 : 0,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(color: Colors.white),
                        child: _listFileFace.length >= 3
                            ? Image.file(
                                _listFileFace[2],
                                fit: BoxFit.cover,
                              )
                            : Container(),
                      ),
                    )
                  ],
                )
                // Text('Quality score: $qualityScore'),
                // Text('Face: ${_listFace.length}'),
                // Text(
                //   'Warning: $warningMsg',
                //   style: TextStyle(color: Colors.red),
                // ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    if (_cameraController.hasListeners) _cameraController.stopImageStream();
    _faceDetector.close();
    _faceVerificationService.dispose();
    _faceAntiSpoofingService.dispose();
    if (_timer != null) _timer!.cancel();
    super.dispose();
  }
}
