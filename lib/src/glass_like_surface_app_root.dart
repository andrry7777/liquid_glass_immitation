import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'config.dart';

class GlassLikeSurfaceAppRoot extends StatefulWidget {
  const GlassLikeSurfaceAppRoot({
    super.key,
    required this.child,
    this.config = const GlassLikeSurfaceConfig(),
    this.motionOffsetListenable,
  });

  final Widget child;
  final GlassLikeSurfaceConfig config;
  final ValueListenable<Offset>? motionOffsetListenable;

  @override
  State<GlassLikeSurfaceAppRoot> createState() => _GlassLikeSurfaceAppRootState();
}

class _GlassLikeSurfaceAppRootState extends State<GlassLikeSurfaceAppRoot>
    with SingleTickerProviderStateMixin {
  Offset _pointerOffset = Offset.zero;
  Offset _motionOffset = Offset.zero;
  Offset _pointerResetFrom = Offset.zero;
  late final AnimationController _pointerResetController;
  late final Animation<double> _pointerResetCurve;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  static const Duration _pointerResetDuration = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _pointerResetController = AnimationController(
      vsync: this,
      duration: _pointerResetDuration,
    );
    _pointerResetCurve = CurvedAnimation(
      parent: _pointerResetController,
      curve: Curves.easeOutCubic,
    );
    _pointerResetController.addListener(_handlePointerResetTick);
    widget.motionOffsetListenable?.addListener(_handleMotionUpdate);
  }

  @override
  void didUpdateWidget(GlassLikeSurfaceAppRoot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motionOffsetListenable != widget.motionOffsetListenable) {
      oldWidget.motionOffsetListenable?.removeListener(_handleMotionUpdate);
      widget.motionOffsetListenable?.addListener(_handleMotionUpdate);
    }
    if (oldWidget.config != widget.config &&
        (!widget.config.enablePointerParallax ||
            widget.config.reduceMotion)) {
      _pointerResetController.stop();
      if (_pointerOffset != Offset.zero) {
        setState(() {
          _pointerOffset = Offset.zero;
        });
      }
    }
  }

  @override
  void dispose() {
    widget.motionOffsetListenable?.removeListener(_handleMotionUpdate);
    _pointerResetController.dispose();
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
    if (_pointerResetController.isAnimating) {
      _pointerResetController.stop();
    }
    if (_pointerOffset == globalPosition) {
      return;
    }
    setState(() {
      _pointerOffset = globalPosition;
    });
  }

  void _resetPointer() {
    if (!widget.config.enablePointerParallax) {
      return;
    }
    if (widget.config.reduceMotion) {
      if (_pointerOffset == Offset.zero) {
        return;
      }
      setState(() {
        _pointerOffset = Offset.zero;
      });
      return;
    }
    if (_pointerOffset == Offset.zero) {
      return;
    }
    _pointerResetFrom = _pointerOffset;
    _pointerResetController.forward(from: 0.0);
  }

  void _handlePointerResetTick() {
    final t = _pointerResetCurve.value;
    final next = Offset.lerp(_pointerResetFrom, Offset.zero, t)!;
    if (next == _pointerOffset) {
      return;
    }
    setState(() {
      _pointerOffset = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _GlassLikeSurfaceScope(
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

class _GlassLikeSurfaceScope extends InheritedWidget {
  const _GlassLikeSurfaceScope({
    required this.config,
    required this.pointerOffset,
    required this.motionOffset,
    required this.repaintBoundaryKey,
    required super.child,
  });

  final GlassLikeSurfaceConfig config;
  final Offset pointerOffset;
  final Offset motionOffset;
  final GlobalKey repaintBoundaryKey;

  static _GlassLikeSurfaceScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_GlassLikeSurfaceScope>();
  }

  @override
  bool updateShouldNotify(_GlassLikeSurfaceScope oldWidget) {
    return config != oldWidget.config ||
        pointerOffset != oldWidget.pointerOffset ||
        motionOffset != oldWidget.motionOffset ||
        repaintBoundaryKey != oldWidget.repaintBoundaryKey;
  }
}

GlassLikeSurfaceConfig glassLikeSurfaceConfigOf(BuildContext context) {
  return _GlassLikeSurfaceScope.maybeOf(context)?.config ??
      const GlassLikeSurfaceConfig();
}

Offset glassLikeSurfacePointerOffsetOf(BuildContext context) {
  return _GlassLikeSurfaceScope.maybeOf(context)?.pointerOffset ?? Offset.zero;
}

Offset glassLikeSurfaceMotionOffsetOf(BuildContext context) {
  return _GlassLikeSurfaceScope.maybeOf(context)?.motionOffset ?? Offset.zero;
}

GlobalKey? glassLikeSurfaceRepaintBoundaryKeyOf(BuildContext context) {
  return _GlassLikeSurfaceScope.maybeOf(context)?.repaintBoundaryKey;
}
