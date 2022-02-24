import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imageLib;

import '../data/firebase_database.dart';
import '../models/user.dart';
import '../utils/image_utils.dart';

class FaceVerificationService {
  late Interpreter _interpreter;
  double threshold = 0.6;

  late List _predictedData;

  List get predictedData => _predictedData;

  Future initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset("mobilefacenet.tflite");
      print('model loaded successfully');
    } catch (e) {
      print('Failed to load model.');
      print(e);
    }
  }

  List setCurrentPrediction(CameraImage cameraImage, Face face) {
    List input = preProcess(cameraImage, face);

    input = input.reshape([1, 112, 112, 3]);
    List output = List.generate(1, (index) => List.filled(192, 0));

    _interpreter.run(input, output);
    output = output.reshape([192]);

    _predictedData = List.from(output);
    return _predictedData;
  }

  Future<User?> predict() async {
    return _searchResult(_predictedData);
  }

  Float32List preProcess(CameraImage image, Face faceDetected) {
    imageLib.Image croppedImage = ImageUtils.cropFace(image, faceDetected);
    imageLib.Image img = imageLib.copyResizeCropSquare(croppedImage, 112);
    Float32List imageAsList = imageToByteListFloat32(img);
    return imageAsList;
  }

  imageLib.Image _convertCameraImage(CameraImage image) {
    imageLib.Image img = ImageUtils.convertCameraImage(image)!;
    imageLib.Image img1 = imageLib.copyRotate(img , ImageUtils.imageRotation);
    return img1;
  }

  Float32List imageToByteListFloat32(imageLib.Image image) {
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < 112; i++) {
      for (var j = 0; j < 112; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (imageLib.getRed(pixel) - 128) / 128;
        buffer[pixelIndex++] = (imageLib.getGreen(pixel) - 128) / 128;
        buffer[pixelIndex++] = (imageLib.getBlue(pixel) - 128) / 128;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }

  User? _searchResult(List predictedData){
    List<User> users = FBRealtime.users;
    double minDist = 999;
    double currDist = 0.0;
    User? predictedResult;

    for (User u in users) {
      currDist = _euclideanDistance(u.modelData, predictedData);
      if (currDist <= threshold && currDist < minDist) {
        minDist = currDist;
        predictedResult = u;
      }
    }
    return predictedResult;
  }

  double _euclideanDistance(List e1, List e2) {
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i] - e2[i]), 2);
    }
    return sqrt(sum);
  }

  void setPredictedData(value) {
    this._predictedData = value;
  }
  dispose() {
    _interpreter.close();
  }
}