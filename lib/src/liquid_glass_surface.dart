import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'config.dart';
import 'liquid_glass_app_root.dart';
import 'liquid_glass_group.dart';
import 'liquid_glass_style.dart';
import 'matrix_utils.dart';

class LiquidGlassSurface extends StatefulWidget {
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
  State<LiquidGlassSurface> createState() => _LiquidGlassSurfaceState();
}

class _LiquidGlassSurfaceState extends State<LiquidGlassSurface> {
  Color? _adaptiveTint;
  Brightness? _adaptiveBrightness;
  Timer? _toneMappingTimer;

  @override
  void initState() {
    super.initState();
    _scheduleToneMapping();
  }

  @override
  void didUpdateWidget(LiquidGlassSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _scheduleToneMapping();
    }
  }

  @override
  void dispose() {
    _toneMappingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scopeConfig = liquidGlassConfigOf(context);
    final effectiveConfig = widget.config ?? scopeConfig;
    final pointerOffset = liquidGlassPointerOffsetOf(context);
    final motionOffset = liquidGlassMotionOffsetOf(context);
    final groupScope = LiquidGlassGroupScope.maybeOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final offset = _normalizedPointerOffset(pointerOffset, size, context) +
            motionOffset;
        final blurSigma = effectiveConfig.reduceTransparency
            ? effectiveConfig.blurSigma * 0.4
            : effectiveConfig.blurSigma;
        final blurDownsample = math.max(1.0, effectiveConfig.blurDownsample);
        final distortionStrength = effectiveConfig.reduceMotion
            ? 0
            : effectiveConfig.distortionStrength;
        final usesSharedBlur = groupScope != null;
        final resolvedTint = _adaptiveTint ?? effectiveConfig.tintColor;
        final foreground = _adaptiveBrightness ??
            ThemeData.estimateBrightnessForColor(resolvedTint);
        final blurFilter = ImageFilter.blur(
          sigmaX: blurSigma / blurDownsample,
          sigmaY: blurSigma / blurDownsample,
        );
        final distortionFilter = ImageFilter.matrix(
          buildDistortionMatrix(
            distortionStrength: distortionStrength,
            pointerOffset: offset,
          ),
        );
        final filter = usesSharedBlur
            ? distortionFilter
            : ImageFilter.compose(
                outer: blurFilter,
                inner: distortionFilter,
              );

        return Container(
          margin: widget.margin,
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: BackdropFilter(
              filter: filter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius,
                  color: resolvedTint,
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
                    borderRadius: widget.borderRadius,
                    highlightStrength: effectiveConfig.highlightStrength,
                    pointerOffset: offset,
                  ),
                  child: LiquidGlassStyleScope(
                    brightness: foreground,
                    child: Padding(
                      padding: widget.padding ?? const EdgeInsets.all(16),
                      child: widget.child,
                    ),
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

  void _scheduleToneMapping() {
    _toneMappingTimer?.cancel();
    final config = widget.config ?? const LiquidGlassConfig();
    if (!config.adaptiveTint) {
      return;
    }
    _toneMappingTimer = Timer(config.toneMappingInterval, _updateToneMapping);
  }

  Future<void> _updateToneMapping() async {
    if (!mounted) {
      return;
    }
    final config = widget.config ?? liquidGlassConfigOf(context);
    if (!config.adaptiveTint) {
      return;
    }
    final boundaryKey = liquidGlassRepaintBoundaryKeyOf(context);
    final boundaryContext = boundaryKey?.currentContext;
    if (boundaryContext == null) {
      return;
    }
    final boundary =
        boundaryContext.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return;
    }
    final boundaryBox = boundaryContext.findRenderObject() as RenderBox?;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (boundaryBox == null || renderBox == null) {
      return;
    }
    final boundaryOrigin = boundaryBox.localToGlobal(Offset.zero);
    final surfaceOrigin = renderBox.localToGlobal(Offset.zero);
    final rectInBoundary = Rect.fromLTWH(
      surfaceOrigin.dx - boundaryOrigin.dx,
      surfaceOrigin.dy - boundaryOrigin.dy,
      renderBox.size.width,
      renderBox.size.height,
    );

    final pixelRatio = math.max(0.05, config.toneMappingSampleScale);
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ImageByteFormat.rawRgba);
    image.dispose();
    if (data == null) {
      return;
    }

    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();
    final scaledRect = Rect.fromLTWH(
      rectInBoundary.left * pixelRatio,
      rectInBoundary.top * pixelRatio,
      rectInBoundary.width * pixelRatio,
      rectInBoundary.height * pixelRatio,
    ).intersect(Rect.fromLTWH(0, 0, imageWidth, imageHeight));

    if (scaledRect.isEmpty) {
      return;
    }

    final int left = scaledRect.left.floor();
    final int top = scaledRect.top.floor();
    final int right = scaledRect.right.ceil();
    final int bottom = scaledRect.bottom.ceil();
    final int width = image.width;

    int count = 0;
    int r = 0;
    int g = 0;
    int b = 0;
    final int totalPixels = (right - left) * (bottom - top);
    final int step = math.max(1, (totalPixels / 5000).ceil());

    for (int y = top; y < bottom; y += step) {
      for (int x = left; x < right; x += step) {
        final int index = (y * width + x) * 4;
        r += data.getUint8(index);
        g += data.getUint8(index + 1);
        b += data.getUint8(index + 2);
        count++;
      }
    }

    if (count == 0) {
      return;
    }

    final Color averageColor = Color.fromARGB(
      255,
      (r / count).round(),
      (g / count).round(),
      (b / count).round(),
    );
    final double alpha = config.tintColor.opacity;
    final Color blendedTint = Color.lerp(
      config.tintColor,
      averageColor.withOpacity(alpha),
      0.6,
    )!;
    final brightness = ThemeData.estimateBrightnessForColor(averageColor);

    if (!mounted) {
      return;
    }
    setState(() {
      _adaptiveTint = blendedTint;
      _adaptiveBrightness = brightness;
    });
    _scheduleToneMapping();
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
