import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass/liquid_glass.dart';

void main() {
  test('LiquidGlassConfig supports copyWith', () {
    const config = LiquidGlassConfig(blurSigma: 12);
    final next = config.copyWith(blurSigma: 18);

    expect(next.blurSigma, 18);
    expect(next.distortionStrength, config.distortionStrength);
  });
}
