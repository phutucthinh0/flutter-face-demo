import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_face_demo/data/firebase_database.dart';
import 'package:flutter_face_demo/services/face_anti_spoofing_serverice.dart';
import 'package:flutter_face_demo/services/face_verification_service.dart';
import 'package:flutter_face_demo/services/mask_detection_service.dart';
import 'package:flutter_face_demo/utils/image_utils.dart';
import 'package:flutter_face_demo/utils/isolate_utils.dart';
import 'package:flutter_face_demo/utils/scanner_utils.dart';
import 'package:get/get.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:sizer/sizer.dart';

import '../enums.dart';
import '../helpers/face_dectector_painter.dart';
import '../models/user.dart';
import 'hello.dart';
import 'package:image/image.dart' as imageLib;

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver{
  bool _showDebug = false;
  bool _onBackPress = false;

  bool _isInitialize = true;
  bool _isDetecting = false;
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
  final IsolateUtils isolateUtils = IsolateUtils();

  int laplacianScore = 0;
  double spoofingScore = 0;
  int estimatedTime = 0;
  String warningMsg = "";
  String cautionMsg = "";
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    initStateAsync();
    FBRealtime.readAllUsers();
  }

  initStateAsync() async {
    isolateUtils.start();
    await _maskDetectionService.initialize();
    await _faceAntiSpoofingService.initialize();
    await _faceVerificationService.initialize();
    _cameras = await availableCameras();
    _cameraDescription = _cameras.firstWhere(
      (CameraDescription camera) => camera.lensDirection == CameraLensDirection.front);
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
    if(_onBackPress){
      Get.back();
      return;
    }
    this._cameraImage = _cameraImage;
    _isDetecting = true;
    var startTime = DateTime.now();
    dynamic results = await ScannerUtils.detect(
        image: _cameraImage,
        detectInImage: _faceDetector.processImage,
        imageRotation: _cameraDescription.sensorOrientation);
    setState(() {
      _listFace = results;
    });
    //
    if (_listFace.length != 1) {
      warningMsg = "Chỉ cần có 1 gương mặt";
      if(_listFace.isEmpty){
        setState(() {
          cautionMsg = "Đưa gương mặt vào chính giữa";
        });
      }else{
        setState(() {
          cautionMsg = "Quá nhiều gương mặt";
        });
      }
      delayDetector();
      return;
    }
    //isolate
    var isolateData = IsolateData(_cameraImage, ImageUtils.imageRotation, _listFace[0], _maskDetectionService.interpreter.address, _faceAntiSpoofingService.interpreter.address,_faceVerificationService.interpreter.address, FBRealtime.users);
    ReceivePort responsePort = ReceivePort();
    isolateUtils.sendPort.send(isolateData..responsePort = responsePort.sendPort);
    var response = await responsePort.first;

    var _maskState = response['maskResults'];
    if(_maskState == MaskDetectorState.suspecting){
      warningMsg = "Nghi ngờ";
      delayDetector();
      return;
    }
    if(_maskState == MaskDetectorState.haveMask){
      setState(() {
        cautionMsg = "Vui lòng để toàn bộ gương mặt trong khung, tháo khẩu trang (nếu có)";
      });
      delayDetector();
      return;
    }
    laplacianScore = response['laplacian'];
    if(laplacianScore<200){
      setState(() {
        laplacianScore;
        cautionMsg = "Hình ảnh mờ, hoặc không rõ ràng.\nVui lòng giữ ổn định";
      });
      delayDetector();
      return;
    }
    spoofingScore = response['spoofingResults'];
    if(spoofingScore<0.9){
      setState(() {
        laplacianScore;
        spoofingScore;
        cautionMsg = "Phát hiện giả mạo";
      });
      delayDetector();
      return;
    }
    User? _user = response['verificationUser'];
    if(_user != null){
      File _image = await ImageUtils.saveImage(ImageUtils.cropFace(_cameraImage, _listFace[0]));
      await Get.to(() => HelloScreen(user: _user, image: _image));
    }else{
      warningMsg = "Null";
    }
    // qualityScore = _faceAntiSpoofingService.laplacian(ImageUtils.cropFace(_cameraImage, _listFace[0]));
    // // qualityScore = 902;
    // if (qualityScore < 10){
    //   warningMsg = "Phát hiện giả mạo";
    //   delayDetector();
    //   return;
    // }
    // if (10 <= qualityScore && qualityScore <= 700) {
    //   warningMsg =
    //       "Vui lòng đưa lại gần\n hoặc làm sạch camera\n hoặc đưa ra khu vực đủ sáng";
    //   delayDetector();
    //   return;
    // }
    // if (qualityScore > 700) warningMsg = "ĐANG NHẬN DIỆN";
    // // double score = await _faceAntiSpoofingService.antiSpoofing( ImageUtils.cropFace(_cameraImage, _listFace[0]));
    // setState(() {
    //   qualityScore;
    //   warningMsg;
    // });
    // // delayDetector();
    // // return;
    // if (qualityScore > 700 && !_isSpoofing) {
    //   print('-----------------------');
    //   await _faceVerificationService.setCurrentPrediction(
    //       _cameraImage, _listFace[0]);
    //   User? _user = await _faceVerificationService.predict();
    //   if (_user != null) {
    //     _onPause = true;
    //     setState(() {
    //       _isInitialize = true;
    //     });
    //     if (await _faceAntiSpoofingService.antiSpoofing(ImageUtils.cropFace(_cameraImage, _listFace[0])) < 0.90) {
    //       warningMsg = "Giả mạo";
    //     } else {
    //       File _image = await ImageUtils.saveImage(ImageUtils.cropFace(_cameraImage, _listFace[0]));
    //       await Get.to(() => HelloScreen(user: _user, image: _image));
    //     }
    //     setState(() {
    //       _isInitialize = false;
    //     });
    //     _isDetecting = false;
    //     _onPause = false;
    //   } else {
    //     setState(() {
    //       warningMsg = "Đang nhận diện";
    //     });
    //   }
    //   // Future.delayed(Duration(seconds: 2), () {
    //   //   _isSpoofing = false;
    //   // });
    //   _isSpoofing = false;
    // }
    var esTime = DateTime.now().millisecondsSinceEpoch- startTime.millisecondsSinceEpoch;
    setState(() {
      warningMsg;
      laplacianScore;
      spoofingScore;
      estimatedTime = esTime;
      cautionMsg = "";
    });
    delayDetector();
  }

  delayDetector() {
    Future.delayed(Duration(milliseconds: 100), () => _isDetecting = false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _onBackPress = true;
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Quét khuôn mặt'),
          actions: [
            IconButton(
              onPressed: (){
                setState(() {
                  _showDebug = !_showDebug;
                });
              },
              icon: _showDebug?Icon(Icons.visibility):Icon(Icons.visibility_off),
            )
          ],
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
                  Stack(
                    children: [
                      SizedBox(
                        width: Get.width,
                        height: Get.width*352/288,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: Get.width,
                            height: Get.width * _cameraController.value.aspectRatio,
                            child: Stack(
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
                                Center(
                                  child: Container(
                                    width: Get.width -80,
                                    height: Get.width -50,
                                    decoration: BoxDecoration(
                                        border: Border.all(color: Colors.blue, width: 2)
                                    ),
                                  ),
                                ),
                                if(cautionMsg.isNotEmpty)
                                Center(
                                  child: Container(
                                    width: Get.width -80,
                                    height: Get.width -50,
                                    padding: EdgeInsets.all(10),
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                      Icon(Icons.warning_amber, color: Colors.red, size: 80,),
                                      SizedBox(height: 10),
                                      Text(cautionMsg, style: TextStyle(color: Colors.red, fontSize: 20), textAlign: TextAlign.center,)
                                    ]),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),

                    ],
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
                  if(_showDebug)Column(children: [
                    Text('Laplacian score: $laplacianScore'),
                    Text('Spoofing score: $spoofingScore'),
                    Text('Estimated Time: $estimatedTime'),
                    Text(
                      'Warning: $warningMsg',
                      style: TextStyle(color: Colors.red),
                    ),
                    // ElevatedButton(
                    //     onPressed: () async {
                    //       _done();
                    //       // await dialogAnimationWrapper(
                    //       //     context: context,
                    //       //     slideFrom: 'bottom',
                    //       //     backgroundColor: Colors.transparent,
                    //       //     child: DialogFaceFake());
                    //     },
                    //     child: Text('Test'))
                  ],)
                ],
              ),
      ),
    );
  }

  _done() async {
    var img = ImageUtils.cropFace(_cameraImage, _listFace[0]);
    var file = await ImageUtils.saveImage(img);
    Get.to(HelloScreen(user: User(user: "test", modelData: []), image: file));
  }

  @override
  void dispose() {
    isolateUtils.dispose();
    _faceDetector.close();
    _maskDetectionService.dispose();
    _faceVerificationService.dispose();
    _faceAntiSpoofingService.dispose();
    if (_cameraController.hasListeners) _cameraController.stopImageStream();
    super.dispose();
  }
}
