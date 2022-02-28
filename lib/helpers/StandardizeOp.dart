import 'dart:math';

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class StandardizeOp extends ImageOperator{

  @override
  TensorImage apply(TensorImage image) {
    List<double> pixels = List.generate(image.height * image.width, (index) => image.image.getPixel(index % image.width, index ~/ image.width)*1.0);
    double mean =pixels.reduce((a, b) => a+b)/pixels.length;
    double std = sqrt(pixels.map((e) => pow(e-mean, 2)).reduce((a, b) => a+b) / pixels.length);
    std = max(std, 1/sqrt(pixels.length));
    for(int i =0;i<pixels.length;i++){
      pixels[i] = (pixels[i] - mean) / std;
    }
    TensorBuffer output =TensorBuffer.createFixedSize(image.tensorBuffer.shape,  TfLiteType.float32);
    output.loadList(pixels, shape: image.tensorBuffer.shape);
    return TensorImage.fromTensorBuffer(output);
  }

  @override
  int getOutputImageHeight(int inputImageHeight, int inputImageWidth) {
    // TODO: implement getOutputImageHeight
    throw UnimplementedError();
  }

  @override
  int getOutputImageWidth(int inputImageHeight, int inputImageWidth) {
    // TODO: implement getOutputImageWidth
    throw UnimplementedError();
  }

  @override
  Point<num> inverseTransform(Point<num> point, int inputImageHeight, int inputImageWidth) {
    throw UnimplementedError();
  }

}