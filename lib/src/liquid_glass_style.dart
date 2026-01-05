import 'package:flutter/material.dart';

class LiquidGlassStyleScope extends InheritedWidget {
  const LiquidGlassStyleScope({
    required this.brightness,
    required super.child,
  });

  final Brightness brightness;

  static LiquidGlassStyleScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LiquidGlassStyleScope>();
  }

  @override
  bool updateShouldNotify(LiquidGlassStyleScope oldWidget) {
    return oldWidget.brightness != brightness;
  }
}

class LiquidGlassForeground extends StatelessWidget {
  const LiquidGlassForeground({
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
    final style = LiquidGlassStyleScope.maybeOf(context);
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
