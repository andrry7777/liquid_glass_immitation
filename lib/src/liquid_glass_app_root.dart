import 'dart:ui';

import 'package:flutter/material.dart';

import 'config.dart';

class LiquidGlassAppRoot extends StatefulWidget {
  const LiquidGlassAppRoot({
    super.key,
    required this.child,
    this.config = const LiquidGlassConfig(),
    this.motionOffsetListenable,
  });

  final Widget child;
  final LiquidGlassConfig config;
  final ValueListenable<Offset>? motionOffsetListenable;

  @override
  State<LiquidGlassAppRoot> createState() => _LiquidGlassAppRootState();
}

class _LiquidGlassAppRootState extends State<LiquidGlassAppRoot> {
  Offset _pointerOffset = Offset.zero;
  Offset _motionOffset = Offset.zero;
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.motionOffsetListenable?.addListener(_handleMotionUpdate);
  }

  @override
  void didUpdateWidget(LiquidGlassAppRoot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motionOffsetListenable != widget.motionOffsetListenable) {
      oldWidget.motionOffsetListenable?.removeListener(_handleMotionUpdate);
      widget.motionOffsetListenable?.addListener(_handleMotionUpdate);
    }
  }

  @override
  void dispose() {
    widget.motionOffsetListenable?.removeListener(_handleMotionUpdate);
    super.dispose();
  }

  void _handleMotionUpdate() {
    final offset = widget.motionOffsetListenable?.value ?? Offset.zero;
    if (offset == _motionOffset) {
      return;
    }
    setState(() {
      _motionOffset = offset;
    });
  }

  void _updatePointer(Offset globalPosition) {
    if (!widget.config.enablePointerParallax || widget.config.reduceMotion) {
      return;
    }
    setState(() {
      _pointerOffset = globalPosition;
    });
  }

  void _resetPointer() {
    if (!widget.config.enablePointerParallax || widget.config.reduceMotion) {
      return;
    }
    setState(() {
      _pointerOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _LiquidGlassScope(
      config: widget.config,
      pointerOffset: _pointerOffset,
      motionOffset: _motionOffset,
      repaintBoundaryKey: _repaintBoundaryKey,
      child: RepaintBoundary(
        key: _repaintBoundaryKey,
        child: Listener(
          onPointerHover: (event) => _updatePointer(event.position),
          onPointerMove: (event) => _updatePointer(event.position),
          onPointerDown: (event) => _updatePointer(event.position),
          onPointerUp: (_) => _resetPointer(),
          onPointerCancel: (_) => _resetPointer(),
          child: widget.child,
        ),
      ),
    );
  }
}

class _LiquidGlassScope extends InheritedWidget {
  const _LiquidGlassScope({
    required this.config,
    required this.pointerOffset,
    required this.motionOffset,
    required this.repaintBoundaryKey,
    required super.child,
  });

  final LiquidGlassConfig config;
  final Offset pointerOffset;
  final Offset motionOffset;
  final GlobalKey repaintBoundaryKey;

  static _LiquidGlassScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_LiquidGlassScope>();
  }

  @override
  bool updateShouldNotify(_LiquidGlassScope oldWidget) {
    return config != oldWidget.config ||
        pointerOffset != oldWidget.pointerOffset ||
        motionOffset != oldWidget.motionOffset ||
        repaintBoundaryKey != oldWidget.repaintBoundaryKey;
  }
}

LiquidGlassConfig liquidGlassConfigOf(BuildContext context) {
  return _LiquidGlassScope.maybeOf(context)?.config ??
      const LiquidGlassConfig();
}

Offset liquidGlassPointerOffsetOf(BuildContext context) {
  return _LiquidGlassScope.maybeOf(context)?.pointerOffset ?? Offset.zero;
}

Offset liquidGlassMotionOffsetOf(BuildContext context) {
  return _LiquidGlassScope.maybeOf(context)?.motionOffset ?? Offset.zero;
}

GlobalKey? liquidGlassRepaintBoundaryKeyOf(BuildContext context) {
  return _LiquidGlassScope.maybeOf(context)?.repaintBoundaryKey;
}
