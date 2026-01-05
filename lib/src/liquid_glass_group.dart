import 'dart:ui';

import 'package:flutter/material.dart';

import 'config.dart';
import 'liquid_glass_app_root.dart';

class LiquidGlassGroup extends StatelessWidget {
  const LiquidGlassGroup({
    super.key,
    required this.child,
    this.config,
    this.clipRect = true,
  });

  final Widget child;
  final LiquidGlassConfig? config;
  final bool clipRect;

  @override
  Widget build(BuildContext context) {
    final scopeConfig = liquidGlassConfigOf(context);
    final effectiveConfig = config ?? scopeConfig;
    final blurSigma = effectiveConfig.reduceTransparency
        ? effectiveConfig.blurSigma * 0.4
        : effectiveConfig.blurSigma;
    final blurDownsample = effectiveConfig.blurDownsample.clamp(1.0, 4.0);
    final filter = ImageFilter.blur(
      sigmaX: blurSigma / blurDownsample,
      sigmaY: blurSigma / blurDownsample,
    );

    final content = BackdropFilter(
      filter: filter,
      child: child,
    );

    return LiquidGlassGroupScope(
      child: clipRect ? ClipRect(child: content) : content,
    );
  }
}

class LiquidGlassGroupScope extends InheritedWidget {
  const LiquidGlassGroupScope({
    required super.child,
  });

  static LiquidGlassGroupScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LiquidGlassGroupScope>();
  }

  @override
  bool updateShouldNotify(LiquidGlassGroupScope oldWidget) => false;
}
