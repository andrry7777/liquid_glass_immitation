import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'config.dart';
import 'liquid_glass_app_root.dart';
import 'matrix_utils.dart';

class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding,
    this.margin,
    this.config,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final LiquidGlassConfig? config;

  @override
  Widget build(BuildContext context) {
    final scopeConfig = liquidGlassConfigOf(context);
    final effectiveConfig = config ?? scopeConfig;
    final pointerOffset = liquidGlassPointerOffsetOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final offset = _normalizedPointerOffset(pointerOffset, size, context);
        final blurSigma = effectiveConfig.reduceTransparency
            ? effectiveConfig.blurSigma * 0.4
            : effectiveConfig.blurSigma;
        final distortionStrength = effectiveConfig.reduceMotion
            ? 0
            : effectiveConfig.distortionStrength;
        final filter = ImageFilter.compose(
          outer: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          inner: ImageFilter.matrix(
            buildDistortionMatrix(
              distortionStrength: distortionStrength,
              pointerOffset: offset,
            ),
          ),
        );

        return Container(
          margin: margin,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: filter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  color: effectiveConfig.tintColor,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 24,
                      color: Colors.black.withOpacity(
                        effectiveConfig.shadowStrength,
                      ),
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _GlassHighlightPainter(
                    borderRadius: borderRadius,
                    highlightStrength: effectiveConfig.highlightStrength,
                    pointerOffset: offset,
                  ),
                  child: Padding(
                    padding: padding ?? const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Offset _normalizedPointerOffset(
    Offset pointerOffset,
    Size size,
    BuildContext context,
  ) {
    if (size.isEmpty) {
      return Offset.zero;
    }
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return Offset.zero;
    }
    final local = renderBox.globalToLocal(pointerOffset);
    final dx = (local.dx / size.width) * 2 - 1;
    final dy = (local.dy / size.height) * 2 - 1;
    return Offset(dx.clamp(-1, 1), dy.clamp(-1, 1));
  }
}

class _GlassHighlightPainter extends CustomPainter {
  _GlassHighlightPainter({
    required this.borderRadius,
    required this.highlightStrength,
    required this.pointerOffset,
  });

  final BorderRadius borderRadius;
  final double highlightStrength;
  final Offset pointerOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);
    final dx = pointerOffset.dx * 0.35;
    final dy = pointerOffset.dy * 0.35;

    final highlightGradient = RadialGradient(
      center: Alignment(dx, dy),
      radius: 1.2,
      colors: [
        Colors.white.withOpacity(0.45 * highlightStrength),
        Colors.white.withOpacity(0.0),
      ],
      stops: const [0.0, 1.0],
    );

    final paint = Paint()
      ..shader = highlightGradient.createShader(rect)
      ..blendMode = BlendMode.screen;

    canvas.drawRRect(rrect, paint);

    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.22 * highlightStrength)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, size.shortestSide * 0.005);

    canvas.drawRRect(rrect.deflate(0.5), edgePaint);
  }

  @override
  bool shouldRepaint(covariant _GlassHighlightPainter oldDelegate) {
    return oldDelegate.highlightStrength != highlightStrength ||
        oldDelegate.pointerOffset != pointerOffset ||
        oldDelegate.borderRadius != borderRadius;
  }
}
