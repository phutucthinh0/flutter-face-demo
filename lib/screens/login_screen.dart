import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_face_demo/services/face_anti_spoofing_serverice.dart';
import 'package:flutter_face_demo/services/face_verification_service.dart';
import 'package:flutter_face_demo/utils/image_utils.dart';
import 'package:flutter_face_demo/utils/scanner_utils.dart';
import 'package:get/get.dart';
import 'package:google_ml_vision/google_ml_vision.dart';

import '../enums.dart';
import '../helpers/face_dectector_painter.dart';
import '../models/user.dart';
import 'hello.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
  double spoofingScore = 0;
  String warningMsg = "";
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
  void onLatestImageAvailable(CameraImage _cameraImage)async{
    if (_isDetecting) return;
    _isDetecting = true;
    ScannerUtils.detect(image: _cameraImage, detectInImage: _faceDetector.processImage, imageRotation: _cameraDescription.sensorOrientation)
        .then((dynamic results)async{
            if(results is List<Face>){
              setState(() {
                _listFace = results;
              });
              if(_listFace.length == 1){
                qualityScore = _faceAntiSpoofingService.laplacian(ImageUtils.cropFace(_cameraImage, _listFace[0]));
                if(qualityScore <10) warningMsg = "Phát hiện giả mạo";
                if(10<=qualityScore && qualityScore <=500) warningMsg = "Vui lòng đưa lại gần\n hoặc làm sạch camera\n hoặc đưa ra khu vực đủ sáng";
                if(qualityScore >500 ) warningMsg = "ĐANG NHẬN DIỆN";
                setState(() {
                  qualityScore;
                  warningMsg;
                });
                if(qualityScore >500 && !_isSpoofing){
                  print('-----------------------');
                  _isSpoofing = true;
                  double score = await _faceAntiSpoofingService.antiSpoofing(ImageUtils.cropFace(_cameraImage, _listFace[0]));
                  setState(() {
                    spoofingScore =  score;
                  });
                  if(spoofingScore > 0.9){
                    await _faceVerificationService.setCurrentPrediction(_cameraImage,_listFace[0]);
                    User? _user = await _faceVerificationService.predict();
                    if(_user!=null){
                      await _cameraController.stopImageStream();
                      await Get.to(()=>HelloScreen(user: _user));
                      _isDetecting = false;
                      _cameraController.startImageStream(onLatestImageAvailable);
                    }
                  }
                  Future.delayed(Duration(seconds: 2),(){
                    _isSpoofing = false;
                  });
                }
              }else{
                qualityScore = 0;
                warningMsg = "Chỉ được có 1 gương mặt";
              }
            }
          })
        .whenComplete(() => Future.delayed(Duration(milliseconds: 100), () => _isDetecting = false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng nhập'),
      ),
      body: _isInitialize
          ? Center(child: Text('Initialize'))
          : Column(
            children: [
              Container(
                width: Get.width,
                height: Get.width*_cameraController.value.aspectRatio,
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
                              rotationIntToImageRotation(_cameraDescription.sensorOrientation)
                          ),
                        ),
                      ],
                    ),
                    Center(
                      child: Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue, width: 2)
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Text('Quality score: $qualityScore         Spoofing score: ${spoofingScore.toStringAsFixed(3)}'),
              Text('Face: ${_listFace.length}'),
              Text('Warning: $warningMsg', style: TextStyle(color: Colors.red),),
            ],
          ),
    );
  }
  @override
  void dispose() {
    _faceDetector.close();
    _faceAntiSpoofingService.dispose();
    if(_cameraController.hasListeners) _cameraController.stopImageStream();
    super.dispose();
  }
}
