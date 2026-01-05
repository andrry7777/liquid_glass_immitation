import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'config.dart';
import 'glass_like_surface_app_root.dart';
import 'glass_like_surface_group.dart';
import 'glass_like_surface_style.dart';
import 'matrix_utils.dart';

class GlassLikeSurfaceMergeGroup extends StatefulWidget {
  const GlassLikeSurfaceMergeGroup({
    super.key,
    required this.child,
    this.config,
  });

  final Widget child;
  final GlassLikeSurfaceConfig? config;

  @override
  State<GlassLikeSurfaceMergeGroup> createState() => _GlassLikeSurfaceMergeGroupState();
}

class _GlassLikeSurfaceMergeGroupState extends State<GlassLikeSurfaceMergeGroup> {
  final Map<GlobalKey, BorderRadius> _targets =
      <GlobalKey, BorderRadius>{};
  List<_MergeTargetInfo> _targetInfo = const <_MergeTargetInfo>[];
  _MergedPathResult _merged = const _MergedPathResult(null, null);
  int _clipVersion = 0;
  bool _tracking = false;

  Color? _adaptiveTint;
  Brightness? _adaptiveBrightness;
  Timer? _toneMappingTimer;

  @override
  void initState() {
    super.initState();
    _scheduleToneMapping();
  }

  @override
  void didUpdateWidget(GlassLikeSurfaceMergeGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _scheduleToneMapping();
    }
  }

  @override
  void dispose() {
    _tracking = false;
    _toneMappingTimer?.cancel();
    super.dispose();
  }

  void _registerTarget(GlobalKey key, BorderRadius radius) {
    _targets[key] = radius;
    if (!_tracking) {
      _startTracking();
    }
  }

  void _unregisterTarget(GlobalKey key) {
    _targets.remove(key);
    if (_targets.isEmpty) {
      _tracking = false;
    }
  }

  void _startTracking() {
    if (_tracking) {
      return;
    }
    _tracking = true;
    _scheduleMeasureLoop();
  }

  void _scheduleMeasureLoop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_tracking) {
        return;
      }
      _measureTargets();
      _scheduleMeasureLoop();
    });
  }

  void _measureTargets() {
    final groupBox = context.findRenderObject() as RenderBox?;
    if (groupBox == null || !groupBox.hasSize) {
      return;
    }

    final entries = _targets.entries.toList()
      ..sort((a, b) => a.key.hashCode.compareTo(b.key.hashCode));
    final List<_MergeTargetInfo> info = <_MergeTargetInfo>[];

    for (final entry in entries) {
      final targetContext = entry.key.currentContext;
      if (targetContext == null) {
        continue;
      }
      final targetBox = targetContext.findRenderObject() as RenderBox?;
      if (targetBox == null || !targetBox.hasSize) {
        continue;
      }
      final offset =
          targetBox.localToGlobal(Offset.zero, ancestor: groupBox);
      info.add(
        _MergeTargetInfo(
          rect: offset & targetBox.size,
          borderRadius: entry.value,
        ),
      );
    }

    if (_mergeTargetsEqual(info, _targetInfo)) {
      return;
    }

    final merged = _buildMergedPath(info);
    setState(() {
      _targetInfo = info;
      _merged = merged;
      _clipVersion++;
    });
    _scheduleToneMapping();
  }

  bool _mergeTargetsEqual(
    List<_MergeTargetInfo> next,
    List<_MergeTargetInfo> current,
  ) {
    if (next.length != current.length) {
      return false;
    }
    for (int i = 0; i < next.length; i++) {
      if (next[i] != current[i]) {
        return false;
      }
    }
    return true;
  }

  _MergedPathResult _buildMergedPath(List<_MergeTargetInfo> info) {
    if (info.isEmpty) {
      return const _MergedPathResult(null, null);
    }
    Path? path;
    Rect? bounds;
    for (final target in info) {
      final rrect = target.borderRadius.toRRect(target.rect);
      final targetPath = Path()..addRRect(rrect);
      if (path == null) {
        path = targetPath;
      } else {
        path = Path.combine(PathOperation.union, path, targetPath);
      }
      bounds =
          bounds == null ? target.rect : bounds.expandToInclude(target.rect);
    }
    return _MergedPathResult(path, bounds);
  }

  @override
  Widget build(BuildContext context) {
    final scopeConfig = glassLikeSurfaceConfigOf(context);
    final effectiveConfig = widget.config ?? scopeConfig;
    final pointerOffset = glassLikeSurfacePointerOffsetOf(context);
    final motionOffset = glassLikeSurfaceMotionOffsetOf(context);
    final groupScope = GlassLikeSurfaceGroupScope.maybeOf(context);

    return _GlassLikeSurfaceMergeScope(
      state: this,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final offset = _normalizedPointerOffset(pointerOffset, size, context) +
              motionOffset;
          final blurSigma = effectiveConfig.reduceTransparency
              ? effectiveConfig.blurSigma * 0.4
              : effectiveConfig.blurSigma;
          final blurDownsample =
              math.max(1.0, effectiveConfig.blurDownsample);
          final distortionStrength = effectiveConfig.reduceMotion
              ? 0.0
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

          final path = _merged.path;
          final bounds = _merged.bounds;
          final hasSurface = path != null && bounds != null && !bounds.isEmpty;

          if (!hasSurface) {
            return GlassLikeSurfaceStyleScope(
              brightness: foreground,
              child: widget.child,
            );
          }

          return Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned.fill(
                child: ClipPath(
                  clipper: _MergedClipper(path, _clipVersion),
                  child: BackdropFilter(
                    filter: filter,
                    child: CustomPaint(
                      painter: _MergedSurfacePainter(
                        path: path,
                        bounds: bounds,
                        tintColor: resolvedTint,
                        shadowStrength: effectiveConfig.shadowStrength,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _MergedHighlightPainter(
                    path: path,
                    bounds: bounds,
                    highlightStrength: effectiveConfig.highlightStrength,
                    pointerOffset: offset,
                  ),
                ),
              ),
              GlassLikeSurfaceStyleScope(
                brightness: foreground,
                child: widget.child,
              ),
            ],
          );
        },
      ),
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
    final config = widget.config ?? const GlassLikeSurfaceConfig();
    if (!config.adaptiveTint) {
      return;
    }
    _toneMappingTimer = Timer(config.toneMappingInterval, _updateToneMapping);
  }

  Future<void> _updateToneMapping() async {
    if (!mounted) {
      return;
    }
    final config = widget.config ?? glassLikeSurfaceConfigOf(context);
    if (!config.adaptiveTint) {
      return;
    }
    final unionBounds = _merged.bounds;
    if (unionBounds == null || unionBounds.isEmpty) {
      return;
    }
    final boundaryKey = glassLikeSurfaceRepaintBoundaryKeyOf(context);
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
      surfaceOrigin.dx - boundaryOrigin.dx + unionBounds.left,
      surfaceOrigin.dy - boundaryOrigin.dy + unionBounds.top,
      unionBounds.width,
      unionBounds.height,
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
    final double alpha = config.tintColor.a;
    final Color blendedTint = Color.lerp(
      config.tintColor,
      averageColor.withValues(alpha: alpha),
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

class GlassLikeSurfaceMergeTarget extends StatefulWidget {
  const GlassLikeSurfaceMergeTarget({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsets? padding;

  @override
  State<GlassLikeSurfaceMergeTarget> createState() => _GlassLikeSurfaceMergeTargetState();
}

class _GlassLikeSurfaceMergeTargetState extends State<GlassLikeSurfaceMergeTarget> {
  final GlobalKey _targetKey = GlobalKey();
  _GlassLikeSurfaceMergeScope? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextScope = _GlassLikeSurfaceMergeScope.maybeOf(context);
    if (_scope != nextScope) {
      _scope?.unregisterTarget(_targetKey);
      _scope = nextScope;
    }
    _scope?.registerTarget(_targetKey, widget.borderRadius);
  }

  @override
  void didUpdateWidget(GlassLikeSurfaceMergeTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.borderRadius != oldWidget.borderRadius) {
      _scope?.registerTarget(_targetKey, widget.borderRadius);
    }
  }

  @override
  void dispose() {
    _scope?.unregisterTarget(_targetKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.padding == null
        ? widget.child
        : Padding(padding: widget.padding!, child: widget.child);
    return KeyedSubtree(
      key: _targetKey,
      child: child,
    );
  }
}

class _GlassLikeSurfaceMergeScope extends InheritedWidget {
  const _GlassLikeSurfaceMergeScope({
    required this.state,
    required super.child,
  });

  final _GlassLikeSurfaceMergeGroupState state;

  static _GlassLikeSurfaceMergeScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_GlassLikeSurfaceMergeScope>();
  }

  void registerTarget(GlobalKey key, BorderRadius radius) {
    state._registerTarget(key, radius);
  }

  void unregisterTarget(GlobalKey key) {
    state._unregisterTarget(key);
  }

  @override
  bool updateShouldNotify(_GlassLikeSurfaceMergeScope oldWidget) => false;
}

class _MergeTargetInfo {
  const _MergeTargetInfo({
    required this.rect,
    required this.borderRadius,
  });

  final Rect rect;
  final BorderRadius borderRadius;

  @override
  bool operator ==(Object other) {
    return other is _MergeTargetInfo &&
        other.rect == rect &&
        other.borderRadius == borderRadius;
  }

  @override
  int get hashCode => Object.hash(rect, borderRadius);
}

class _MergedPathResult {
  const _MergedPathResult(this.path, this.bounds);

  final Path? path;
  final Rect? bounds;
}

class _MergedClipper extends CustomClipper<Path> {
  const _MergedClipper(this.path, this.version);

  final Path path;
  final int version;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(covariant _MergedClipper oldClipper) {
    return oldClipper.version != version;
  }
}

class _MergedSurfacePainter extends CustomPainter {
  _MergedSurfacePainter({
    required this.path,
    required this.bounds,
    required this.tintColor,
    required this.shadowStrength,
  });

  final Path path;
  final Rect bounds;
  final Color tintColor;
  final double shadowStrength;

  @override
  void paint(Canvas canvas, Size size) {
    if (shadowStrength > 0) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: shadowStrength)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          _sigmaForBlurRadius(24),
        );
      canvas.save();
      canvas.translate(0, 12);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
    }

    final fillPaint = Paint()..color = tintColor;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _MergedSurfacePainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.bounds != bounds ||
        oldDelegate.tintColor != tintColor ||
        oldDelegate.shadowStrength != shadowStrength;
  }
}

class _MergedHighlightPainter extends CustomPainter {
  _MergedHighlightPainter({
    required this.path,
    required this.bounds,
    required this.highlightStrength,
    required this.pointerOffset,
  });

  final Path path;
  final Rect bounds;
  final double highlightStrength;
  final Offset pointerOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final dx = pointerOffset.dx * 0.35;
    final dy = pointerOffset.dy * 0.35;

    final highlightGradient = RadialGradient(
      center: Alignment(dx, dy),
      radius: 1.2,
      colors: [
        Colors.white.withValues(alpha: 0.45 * highlightStrength),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 1.0],
    );

    final paint = Paint()
      ..shader = highlightGradient.createShader(bounds)
      ..blendMode = BlendMode.screen;

    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(bounds, paint);
    canvas.restore();

    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22 * highlightStrength)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, bounds.shortestSide * 0.005);

    canvas.drawPath(path, edgePaint);
  }

  @override
  bool shouldRepaint(covariant _MergedHighlightPainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.bounds != bounds ||
        oldDelegate.highlightStrength != highlightStrength ||
        oldDelegate.pointerOffset != pointerOffset;
  }
}

double _sigmaForBlurRadius(double radius) {
  return radius * 0.57735 + 0.5;
}
