import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imageLib;

import '../utils/image_utils.dart';

class FaceAntiSpoofingService{
  final int INPUT_IMAGE_SIZE = 256;
  final double THRESHOLD = 0.2;
  final int ROUTE_INDEX = 6;
  final int LAPLACE_THRESHOLD = 50;
  final int LAPLACIAN_THRESHOLD = 1000;
  late Interpreter _interpreter;
  FaceAntiSpoofingService();
  Future initialize() async {
    try {
      InterpreterOptions _in = InterpreterOptions();
      _in.threads = 4;
      _interpreter = await Interpreter.fromAsset("faceantispoofing.tflite", options: _in);
      print('model loaded successfully');
    } catch (e) {
      print('Failed to load model.');
      print(e);
    }
  }
  Future<double> antiSpoofing (imageLib.Image preImage) async {
    final inputImage = imageLib.copyResizeCropSquare(preImage, 256);
    final List img = normalizeImage(inputImage);
    var input = [img.reshape([1,256,256,3])];
    var clss_pred = List.generate(1, (index) => List.filled(8, 0.1, growable: false));
    var leaf_node_mask = List.generate(1, (index) => List.filled(8, 0.1, growable: false));
    Map<int, Object> outputs = {
      0:clss_pred,
      1:leaf_node_mask,
    };
    _interpreter.runForMultipleInputs(input, outputs);
    return leaf_score1(clss_pred, leaf_node_mask);
  }
  double leaf_score1(List clss_pred, List leaf_node_mask) {
    double score = 0;
    for (int i = 0; i < 8; i++) {
      score += ((clss_pred[0][i]) * leaf_node_mask[0][i]).abs();
    }
  return score;
  }
  List normalizeImage(imageLib.Image image){
    int h = image.height;
    int w = image.width;
    List floatValues = List.generate(h, (e0) => List.generate(w,(e1) => List.generate(3,(e2) => 0.0)));
    double imageStd = 255;
    List<int> pixels = List.generate(h*w, (index) => image.getPixel( index%w, index~/w));
    for (int i = 0; i < h; i++) {
      for (int j = 0; j < w; j++) {
        final int val = pixels[i * w + j];
        double r = ((val >> 16) & 0xFF) / imageStd;
        double g = ((val >> 8) & 0xFF) / imageStd;
        double b = (val & 0xFF) / imageStd;
        List<double> arr = [r,g,b];
        floatValues[i][j] = arr;
      }
    }
    return floatValues;
  }
  int laplacian(imageLib.Image preImage){
    final inputImage = imageLib.copyResizeCropSquare(preImage, 256);
    var laplace = [[0, 1, 0], [1, -4, 1], [0, 1, 0]];
    int size = laplace.length;
    List<List<int>> img = ImageUtils.convertGreyImg(inputImage);
    int height =img.length;
    int width= img[0].length;
    int score = 0;
    for (int x = 0; x < height - size + 1; x++){
      for (int y = 0; y < width - size + 1; y++){
        int result = 0;
        for (int i = 0; i < size; i++){
          for (int j = 0; j < size; j++){
            result += (img[x + i][y + j] & 0xFF) * laplace[i][j];
          }
        }
        if (result > LAPLACE_THRESHOLD) {
          score++;
        }
      }
    }
    return score;
  }
  dispose(){
    _interpreter.close();
  }
}