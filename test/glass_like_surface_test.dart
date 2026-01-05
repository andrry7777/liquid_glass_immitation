import 'package:flutter_test/flutter_test.dart';
import 'package:glass_like_surface/glass_like_surface.dart';

void main() {
  test('GlassLikeSurfaceConfig supports copyWith', () {
    const config = GlassLikeSurfaceConfig(blurSigma: 12);
    final next = config.copyWith(blurSigma: 18);

    expect(next.blurSigma, 18);
    expect(next.distortionStrength, config.distortionStrength);
  });
}
