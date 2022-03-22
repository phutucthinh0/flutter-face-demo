import 'package:flutter/material.dart';
import 'package:google_ml_vision/google_ml_vision.dart';

import '../enums.dart';
import 'coordinates_translator.dart';

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(this.face, this.absoluteImageSize, this.rotation, [this.color = Colors.red]);

  final Face face;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = color;
    final List<Offset> _listOffset = face.getContour(FaceContourType.face)!.positionsList;

    canvas.drawRect(
      // Rect.fromLTRB(
      //   translateX(face.boundingBox.left, rotation, size, absoluteImageSize),
      //   translateY(face.boundingBox.top, rotation, size, absoluteImageSize),
      //   translateX(face.boundingBox.right, rotation, size, absoluteImageSize),
      //   translateY(face.boundingBox.bottom, rotation, size, absoluteImageSize),
      // ),
      Rect.fromLTRB(
        translateX(_listOffset[28].dx, rotation, size, absoluteImageSize),
        translateY(_listOffset[0].dy, rotation, size, absoluteImageSize),
        translateX(_listOffset[9].dx, rotation, size, absoluteImageSize),
        translateY(_listOffset[18].dy, rotation, size, absoluteImageSize),
      ),
      paint,
    );

    void paintContour(FaceContourType type) {
          final faceContour = face.getContour(type);
          if (faceContour?.positionsList != null) {
            for (Offset point in faceContour!.positionsList) {
              canvas.drawCircle(
                  Offset(
                    translateX(point.dx, rotation, size, absoluteImageSize),
                    translateY(point.dy, rotation, size, absoluteImageSize),
                  ),
                  1,
                  paint);
            }
          }
        }

        // paintContour(FaceContourType.face);
        // paintContour(FaceContourType.leftEyebrowTop);
        // paintContour(FaceContourType.leftEyebrowBottom);
        // paintContour(FaceContourType.rightEyebrowTop);
        // paintContour(FaceContourType.rightEyebrowBottom);
        // paintContour(FaceContourType.leftEye);
        // paintContour(FaceContourType.rightEye);
        // paintContour(FaceContourType.upperLipTop);
        // paintContour(FaceContourType.upperLipBottom);
        // paintContour(FaceContourType.lowerLipTop);
        // paintContour(FaceContourType.lowerLipBottom);
        // paintContour(FaceContourType.noseBridge);
        // paintContour(FaceContourType.noseBottom);
    // paintContour(FaceContourType.leftCheek);
    // paintContour(FaceContourType.rightCheek);
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.face != face;
  }
}