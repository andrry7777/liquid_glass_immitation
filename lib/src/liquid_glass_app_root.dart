import 'dart:ui';

import 'package:flutter/material.dart';

import 'config.dart';

class LiquidGlassAppRoot extends StatefulWidget {
  const LiquidGlassAppRoot({
    super.key,
    required this.child,
    this.config = const LiquidGlassConfig(),
  });

  final Widget child;
  final LiquidGlassConfig config;

  @override
  State<LiquidGlassAppRoot> createState() => _LiquidGlassAppRootState();
}

class _LiquidGlassAppRootState extends State<LiquidGlassAppRoot> {
  Offset _pointerOffset = Offset.zero;

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
      child: Listener(
        onPointerHover: (event) => _updatePointer(event.position),
        onPointerMove: (event) => _updatePointer(event.position),
        onPointerDown: (event) => _updatePointer(event.position),
        onPointerUp: (_) => _resetPointer(),
        onPointerCancel: (_) => _resetPointer(),
        child: widget.child,
      ),
    );
  }
}

class _LiquidGlassScope extends InheritedWidget {
  const _LiquidGlassScope({
    required this.config,
    required this.pointerOffset,
    required super.child,
  });

  final LiquidGlassConfig config;
  final Offset pointerOffset;

  static _LiquidGlassScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_LiquidGlassScope>();
  }

  @override
  bool updateShouldNotify(_LiquidGlassScope oldWidget) {
    return config != oldWidget.config || pointerOffset != oldWidget.pointerOffset;
  }
}

LiquidGlassConfig liquidGlassConfigOf(BuildContext context) {
  return _LiquidGlassScope.maybeOf(context)?.config ??
      const LiquidGlassConfig();
}

Offset liquidGlassPointerOffsetOf(BuildContext context) {
  return _LiquidGlassScope.maybeOf(context)?.pointerOffset ?? Offset.zero;
}
