import 'package:flutter/material.dart';

class GlassLikeSurfaceStyleScope extends InheritedWidget {
  const GlassLikeSurfaceStyleScope({
    super.key,
    required this.brightness,
    required super.child,
  });

  final Brightness brightness;

  static GlassLikeSurfaceStyleScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GlassLikeSurfaceStyleScope>();
  }

  @override
  bool updateShouldNotify(GlassLikeSurfaceStyleScope oldWidget) {
    return oldWidget.brightness != brightness;
  }
}

class GlassLikeSurfaceForeground extends StatelessWidget {
  const GlassLikeSurfaceForeground({
    super.key,
    required this.child,
    this.lightColor = const Color(0xFF0A0A0A),
    this.darkColor = Colors.white,
  });

  final Widget child;
  final Color lightColor;
  final Color darkColor;

  @override
  Widget build(BuildContext context) {
    final style = GlassLikeSurfaceStyleScope.maybeOf(context);
    final brightness = style?.brightness ?? Theme.of(context).brightness;
    final color = brightness == Brightness.light ? lightColor : darkColor;

    return DefaultTextStyle.merge(
      style: TextStyle(color: color),
      child: IconTheme.merge(
        data: IconThemeData(color: color),
        child: child,
      ),
    );
  }
}
