import 'dart:ui';

Float64List buildDistortionMatrix({
  required double distortionStrength,
  required Offset pointerOffset,
}) {
  final scale = 1 + distortionStrength * 0.25;
  final translateX = -pointerOffset.dx * distortionStrength * 12;
  final translateY = -pointerOffset.dy * distortionStrength * 12;

  return Float64List.fromList([
    scale, 0, 0, 0, // row 1
    0, scale, 0, 0, // row 2
    0, 0, 1, 0, // row 3
    translateX, translateY, 0, 1, // row 4
  ]);
}
