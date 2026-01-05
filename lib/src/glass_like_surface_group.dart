import 'dart:ui';

import 'package:flutter/material.dart';

import 'config.dart';
import 'glass_like_surface_app_root.dart';

class GlassLikeSurfaceGroup extends StatelessWidget {
  const GlassLikeSurfaceGroup({
    super.key,
    required this.child,
    this.config,
    this.clipRect = true,
  });

  final Widget child;
  final GlassLikeSurfaceConfig? config;
  final bool clipRect;

  @override
  Widget build(BuildContext context) {
    final scopeConfig = glassLikeSurfaceConfigOf(context);
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

    return GlassLikeSurfaceGroupScope(
      child: clipRect ? ClipRect(child: content) : content,
    );
  }
}

class GlassLikeSurfaceGroupScope extends InheritedWidget {
  const GlassLikeSurfaceGroupScope({
    super.key,
    required super.child,
  });

  static GlassLikeSurfaceGroupScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GlassLikeSurfaceGroupScope>();
  }

  @override
  bool updateShouldNotify(GlassLikeSurfaceGroupScope oldWidget) => false;
}
