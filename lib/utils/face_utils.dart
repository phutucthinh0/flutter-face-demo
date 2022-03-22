import 'dart:ui';

import 'package:get/get.dart';
import 'package:google_ml_vision/google_ml_vision.dart';

class FaceUtils{
  final Face face;
  final double absolute;
  FaceUtils(this.face, this.absolute);
  bool isStraight(){
    List<Offset> _listPoint = face.getContour(FaceContourType.noseBottom)!.positionsList;
    double leftPoint = _listPoint[1].dx - _listPoint[0].dx;
    double rightPoint = _listPoint[2].dx - _listPoint[1].dx;
    // if(GetPlatform.isIOS){
    //   double _temp= leftPoint;
    //   leftPoint = rightPoint;
    //   rightPoint = _temp;
    // }
    return ((leftPoint - rightPoint).abs() > 5);
  }
  FaceScaleState isScaleLevel1(){
    List<Offset> _listPoint = face.getContour(FaceContourType.face)!.positionsList;
    double distance = (_listPoint[9].dx -  _listPoint[28].dx)*absolute;
    if(distance<80) return FaceScaleState.tooFar;
    if(distance>100) return FaceScaleState.tooClose;
    return FaceScaleState.normal;
  }
  FaceScaleState isScaleLevel2(){
    List<Offset> _listPoint = face.getContour(FaceContourType.face)!.positionsList;
    double distance = (_listPoint[9].dx -  _listPoint[28].dx)*absolute;
    if(distance<110) return FaceScaleState.tooFar;
    if(distance>130) return FaceScaleState.tooClose;
    return FaceScaleState.normal;
  }
  FaceScaleState isScaleLevel3(){
    List<Offset> _listPoint = face.getContour(FaceContourType.face)!.positionsList;
    double distance = (_listPoint[9].dx -  _listPoint[28].dx)*absolute;
    if(distance<160) return FaceScaleState.tooFar;
    if(distance>190) return FaceScaleState.tooClose;
    return FaceScaleState.normal;
  }
}
enum FaceScaleState {
  tooFar,
  tooClose,
  normal
}