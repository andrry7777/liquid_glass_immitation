# liquid_glass

A Flutter package that provides a root widget and reusable surfaces to reproduce an iOS-style liquid glass material across an app.

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:liquid_glass/liquid_glass.dart';

void main() {
  runApp(
    LiquidGlassAppRoot(
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: LiquidGlassSurface(
            child: const Text('Liquid Glass'),
          ),
        ),
      ),
    );
  }
}
```
