import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:image/image.dart' as imageLib;


class MaskDetectionService {
  late Interpreter _interpreter;
  double score = 0;
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
  MaskDetectorState detectMask(imageLib.Image image){
    TensorImage _inputImage = TensorImage(TfLiteType.float32);
    _inputImage.loadImage(image);
    _inputImage = _imageProcessor.process(_inputImage);
    TensorBuffer _outputBuffer = TensorBuffer.createFixedSize([1,2], TfLiteType.float32);
    List _output = [[0.0,0.0]];
    _interpreter.run(_inputImage.buffer, _output);
    bool detect = _output[0][0]>_output[0][1];
    if(detect){
      //have mask
      if(score<5){
        score++;
        return MaskDetectorState.suspecting;
      }else{
        return MaskDetectorState.haveMask;
      }
    }else{
      //no mask
      score = 0;
      return MaskDetectorState.noMask;
    }
  }
  dispose() {
    _interpreter.close();
  }
}
enum MaskDetectorState{
  noMask,
  haveMask,
  suspecting
}