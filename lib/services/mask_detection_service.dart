import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:image/image.dart' as imageLib;

import '../utils/image_utils.dart';

class MaskDetectionService {
  late Interpreter _interpreter;
  final ImageProcessor _imageProcessor = ImageProcessorBuilder()
      .add(ResizeOp(224,224, ResizeMethod.NEAREST_NEIGHBOUR))
      .build();
  MaskDetectionService();
  Future initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset("maskdetector.tflite");
      print('markdetection loaded successfully');
    } catch (e) {
      print('Failed to load markdetection.');
      print(e);
    }
  }
  bool detectMask(imageLib.Image image){
    TensorImage _inputImage = TensorImage(TfLiteType.float32);
    _inputImage.loadImage(image);
    _inputImage = _imageProcessor.process(_inputImage);
    TensorBuffer _outputBuffer = TensorBuffer.createFixedSize([1,2], TfLiteType.float32);
    List _output = [[0.0,0.0]];
    _interpreter.run(_inputImage.buffer, _output);
    return _output[0][0]>_output[0][1];
  }
  dispose() {
    _interpreter.close();
  }
}