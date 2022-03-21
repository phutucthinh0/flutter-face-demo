import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:image/image.dart' as imageLib;

class FaceAntiSpoofingService {
  late Interpreter _interpreterV1;
  late Interpreter _interpreterV2;
  FaceAntiSpoofingService();
  Future initialize([int? interpreterV1Address, int? interpreterV2Address]) async {
    if(interpreterV1Address != null && interpreterV2Address != null){
      _interpreterV1 = Interpreter.fromAddress(interpreterV1Address);
      _interpreterV2 = Interpreter.fromAddress(interpreterV2Address);
      return;
    }
    try {
      InterpreterOptions _in = InterpreterOptions();
      _in.threads = 4;
      _interpreterV1 = await Interpreter.fromAsset("4_0_0_80x80_MiniFASNetV1SE.tflite", options: _in);
      _interpreterV2 = await Interpreter.fromAsset("2.7_80x80_MiniFASNetV2.tflite", options: _in);
      print('model loaded successfully');
    } catch (e) {
      print('Failed to load model.');
      print(e);
    }
  }
  bool antiSpoofingV12(imageLib.Image image){
    var inputImage = preProcess(image);
    List outputV1 = List.generate(1, (index) => List.filled(3, 0.0));
    List outputV2 = List.generate(1, (index) => List.filled(3, 0.0));
    _interpreterV1.run([inputImage], outputV1);
    _interpreterV2.run([inputImage], outputV2);
    print('A--------------------${outputV1}');
    print('A--------------------${outputV2}');
    List softmaxOutputV1 = softmax(outputV1[0]);
    List softmaxOutputV2 = softmax(outputV2[0]);
    List<double> output = [(softmaxOutputV1[0]+softmaxOutputV2[0])/2,(softmaxOutputV1[1]+softmaxOutputV2[1])/2,(softmaxOutputV1[2]+softmaxOutputV2[2])/2 ];
    print('A--------------------${output}');
    final maxIndex = output.indexWhere((element) => element == output.reduce(max)) ;
    if(maxIndex==1){
      print('Real face');
      return true;
    }else{
      print('Fake face');
      return false;
    }
  }
  bool antiSpoofingV1(imageLib.Image image){
    var inputImage = preProcess(image);
    List outputV1 = List.generate(1, (index) => List.filled(3, 0.0));
    _interpreterV1.run([inputImage], outputV1);
    List softmaxOutputV1 = softmax(outputV1[0]);
    List<double> output = [softmaxOutputV1[0],softmaxOutputV1[1],softmaxOutputV1[2]];
    print('A--------------------${output}');
    final maxIndex = output.indexWhere((element) => element == output.reduce(max)) ;
    if(maxIndex==1){
      print('Real face');
      return true;
    }else{
      print('Fake face');
      return false;
    }
  }
  bool antiSpoofingV2(imageLib.Image image){
    var inputImage = preProcess(image);
    List outputV2 = List.generate(1, (index) => List.filled(3, 0.0));
    _interpreterV2.run([inputImage], outputV2);
    List softmaxOutputV2 = softmax(outputV2[0]);
    List<double> output = [softmaxOutputV2[0],softmaxOutputV2[1],softmaxOutputV2[2]];
    print('A--------------------${output}');
    final maxIndex = output.indexWhere((element) => element == output.reduce(max)) ;
    if(maxIndex==1){
      print('Real face');
      return true;
    }else{
      print('Fake face');
      return false;
    }
  }
  List<double> softmax(List<double> input){
    List<double> preProcess = input.map((e) => exp(e)).toList();
    double total = 0;
    for (var element in preProcess) {
      total+= element;
    }
    return preProcess.map((e) => e/total).toList();
  }
  List preProcess(imageLib.Image _img){
    var image = imageLib.copyResizeCropSquare(_img, 80);
    int h = image.height;
    int w = image.width;
    List floatValues = List.generate(h, (e0) => List.generate(w,(e1) => List.generate(3,(e2) => 0.0)));
    double imageStd = 255;
    List<int> pixels = List.generate(h*w, (index) => image.getPixel( index%w, index~/w));
    for (int i = 0; i < h; i++) {
      for (int j = 0; j < w; j++) {
        final int val = pixels[i * w + j];
        double r = ((val >> 16) & 0xFF).toDouble() ;
        double g = ((val >> 8) & 0xFF).toDouble() ;
        double b = (val & 0xFF).toDouble() ;
        List<double> arr = [r,g,b];
        floatValues[i][j] = arr;
      }
    }
    return floatValues.reshape([3,w,h]);
  }

  Interpreter get interpreterV1 => _interpreterV1;
  Interpreter get interpreterV2 => _interpreterV2;
  dispose(){
    _interpreterV1.close();
    _interpreterV2.close();
  }
}