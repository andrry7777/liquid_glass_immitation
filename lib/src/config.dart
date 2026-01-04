import 'dart:ui';

import 'package:flutter/foundation.dart';

@immutable
class LiquidGlassConfig {
  const LiquidGlassConfig({
    this.blurSigma = 20,
    this.distortionStrength = 0.03,
    this.tintColor = const Color(0x66FFFFFF),
    this.highlightStrength = 0.35,
    this.shadowStrength = 0.18,
    this.reduceTransparency = false,
    this.reduceMotion = false,
    this.enablePointerParallax = true,
  });

  final double blurSigma;
  final double distortionStrength;
  final Color tintColor;
  final double highlightStrength;
  final double shadowStrength;
  final bool reduceTransparency;
  final bool reduceMotion;
  final bool enablePointerParallax;

  LiquidGlassConfig copyWith({
    double? blurSigma,
    double? distortionStrength,
    Color? tintColor,
    double? highlightStrength,
    double? shadowStrength,
    bool? reduceTransparency,
    bool? reduceMotion,
    bool? enablePointerParallax,
  }) {
    return LiquidGlassConfig(
      blurSigma: blurSigma ?? this.blurSigma,
      distortionStrength: distortionStrength ?? this.distortionStrength,
      tintColor: tintColor ?? this.tintColor,
      highlightStrength: highlightStrength ?? this.highlightStrength,
      shadowStrength: shadowStrength ?? this.shadowStrength,
      reduceTransparency: reduceTransparency ?? this.reduceTransparency,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      enablePointerParallax: enablePointerParallax ?? this.enablePointerParallax,
    );
  }
}
