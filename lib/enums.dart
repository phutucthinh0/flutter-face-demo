enum InputImageRotation {
  Rotation_0deg,
  Rotation_90deg,
  Rotation_180deg,
  Rotation_270deg
}
InputImageRotation rotationIntToImageRotation(int rotation) {
  switch (rotation) {
    case 90:
      return InputImageRotation.Rotation_90deg;
    case 180:
      return InputImageRotation.Rotation_180deg;
    case 270:
      return InputImageRotation.Rotation_270deg;
    default:
      return InputImageRotation.Rotation_0deg;
  }
}