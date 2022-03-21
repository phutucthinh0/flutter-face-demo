import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter_face_demo/services/face_verification_service.dart';
import 'package:flutter_face_demo/utils/image_utils.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:image/image.dart' as imageLib;

import '../models/user.dart';
import '../services/face_anti_spoofing_service.dart';
import '../services/mask_detection_service.dart';

/// Manages separate Isolate instance for inference
class IsolateUtils {
  static const String DEBUG_NAME = "InferenceIsolate";

  late Isolate _isolate;
  final ReceivePort _receivePort = ReceivePort();
  late SendPort _sendPort;
  SendPort get sendPort => _sendPort;

  void start() async {
    _isolate = await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: DEBUG_NAME,
    );
    _sendPort = await _receivePort.first;
  }
  void dispose(){
    _isolate.kill();
  }

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);
    await for (final IsolateData isolateData in port) {
      if (isolateData != null) {
        final maskDetectionService = MaskDetectionService();
        final faceAntiSpoofingService = FaceAntiSpoofingService();
        final faceVerificationService = FaceVerificationService();
        await maskDetectionService.initialize(isolateData.maskInterpreterAddress);
        await faceAntiSpoofingService.initialize(isolateData.spoofingInterpreterAddress[0],isolateData.spoofingInterpreterAddress[1]);
        await faceVerificationService.initialize(isolateData.verificationInterpreterAddress);
        ImageUtils.imageRotation = isolateData.imageRotation;
        imageLib.Image inputImage = ImageUtils.cropFace(isolateData.cameraImage, isolateData.face);
        MaskDetectorState maskResults = maskDetectionService.detectMask(inputImage);
        bool spoofingResults = false;
        User? user;
        // if(maskResults == MaskDetectorState.noMask){
        //   faceVerificationService.setCurrentPrediction(isolateData.cameraImage, isolateData.face);
        //   user = faceVerificationService.predict(isolateData.users);
        //   if(user != null){
        //     spoofingResults = faceAntiSpoofingService.antiSpoofingV12(inputImage);
        //   }
        // }

        if(maskResults == MaskDetectorState.noMask){
          spoofingResults = faceAntiSpoofingService.antiSpoofingV12(inputImage);
          if(spoofingResults){
            faceVerificationService.setCurrentPrediction(isolateData.cameraImage, isolateData.face);
            user = faceVerificationService.predict(isolateData.users);
          }
        }
        isolateData.responsePort!.send({
          'maskResults': maskResults,
          'spoofingResults': spoofingResults,
          'verificationUser':user
        });
      }
    }
  }
}

/// Bundles data to pass between Isolate
class IsolateData {
  CameraImage cameraImage;
  int imageRotation;
  Face face;
  int maskInterpreterAddress;
  List<int> spoofingInterpreterAddress;
  int verificationInterpreterAddress;
  List<User> users;
  SendPort? responsePort;

  IsolateData(this.cameraImage, this.imageRotation, this.face, this.maskInterpreterAddress, this.spoofingInterpreterAddress, this.verificationInterpreterAddress, this.users);
}