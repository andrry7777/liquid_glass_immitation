import 'dart:ui';

import 'package:flutter/foundation.dart';

@immutable
class GlassLikeSurfaceConfig {
  const GlassLikeSurfaceConfig({
    this.blurSigma = 20,
    this.distortionStrength = 0.03,
    this.tintColor = const Color(0x66FFFFFF),
    this.adaptiveTint = false,
    this.toneMappingSampleScale = 0.1,
    this.toneMappingInterval = const Duration(milliseconds: 250),
    this.highlightStrength = 0.35,
    this.shadowStrength = 0.18,
    this.blurDownsample = 1.0,
    this.reduceTransparency = false,
    this.reduceMotion = false,
    this.enablePointerParallax = true,
  });

  final double blurSigma;
  final double distortionStrength;
  final Color tintColor;
  final bool adaptiveTint;
  final double toneMappingSampleScale;
  final Duration toneMappingInterval;
  final double highlightStrength;
  final double shadowStrength;
  final double blurDownsample;
  final bool reduceTransparency;
  final bool reduceMotion;
  final bool enablePointerParallax;

  GlassLikeSurfaceConfig copyWith({
    double? blurSigma,
    double? distortionStrength,
    Color? tintColor,
    bool? adaptiveTint,
    double? toneMappingSampleScale,
    Duration? toneMappingInterval,
    double? highlightStrength,
    double? shadowStrength,
    double? blurDownsample,
    bool? reduceTransparency,
    bool? reduceMotion,
    bool? enablePointerParallax,
  }) {
    return GlassLikeSurfaceConfig(
      blurSigma: blurSigma ?? this.blurSigma,
      distortionStrength: distortionStrength ?? this.distortionStrength,
      tintColor: tintColor ?? this.tintColor,
      adaptiveTint: adaptiveTint ?? this.adaptiveTint,
      toneMappingSampleScale:
          toneMappingSampleScale ?? this.toneMappingSampleScale,
      toneMappingInterval: toneMappingInterval ?? this.toneMappingInterval,
      highlightStrength: highlightStrength ?? this.highlightStrength,
      shadowStrength: shadowStrength ?? this.shadowStrength,
      blurDownsample: blurDownsample ?? this.blurDownsample,
      reduceTransparency: reduceTransparency ?? this.reduceTransparency,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      enablePointerParallax: enablePointerParallax ?? this.enablePointerParallax,
    );
  }
}
