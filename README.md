# liquid_glass

A Flutter package that recreates an iOS-style liquid glass material with blur, refraction-like distortion, adaptive tinting, and highlight rendering.

## Features

- Real-time backdrop blur with optional downsampling for performance.
- Lightweight distortion to mimic refraction.
- Adaptive tint based on the background sample.
- Pointer-aware highlights and motion parallax support.
- Shared blur groups for multiple glass surfaces.

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  liquid_glass: ^<latest>
```

## Quick Start

Wrap your app with `LiquidGlassAppRoot`, then use `LiquidGlassSurface` where you want glass:

```dart
import 'package:flutter/material.dart';
import 'package:liquid_glass/liquid_glass.dart';

void main() {
  runApp(
    const LiquidGlassAppRoot(
      child: MyApp(),
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

## Configuration

Control the look and behavior through `LiquidGlassConfig`:

```dart
final config = LiquidGlassConfig(
  blurSigma: 20,
  distortionStrength: 0.03,
  tintColor: const Color(0x66FFFFFF),
  adaptiveTint: true,
  highlightStrength: 0.35,
  shadowStrength: 0.18,
  blurDownsample: 1.0,
  reduceTransparency: false,
  reduceMotion: false,
  enablePointerParallax: true,
);

LiquidGlassSurface(
  config: config,
  child: const Text('Configurable Glass'),
);
```

### Configuration reference

Each field is optional; defaults are shown below. Values are tuned for a subtle,
system-like glass effect, but you can push them for a stronger look.

| Field | Default | Details |
| --- | --- | --- |
| `blurSigma` | `20` | Gaussian blur radius. Higher = softer background, more GPU cost. |
| `blurDownsample` | `1.0` | Downsample factor for blur (>= 1.0). Higher values reduce cost but soften detail. `LiquidGlassGroup` clamps this to 4.0. |
| `distortionStrength` | `0.03` | Strength of the refraction-like distortion. Set to `0.0` for a pure blur. |
| `tintColor` | `Color(0x66FFFFFF)` | Base tint over the glass. Alpha controls material density. |
| `adaptiveTint` | `false` | When true, samples the background and blends `tintColor` toward the average color. |
| `toneMappingSampleScale` | `0.1` | Sampling scale for adaptive tint (0 < value <= 1). Lower values are cheaper but less accurate. |
| `toneMappingInterval` | `250ms` | Sampling interval for adaptive tint. Lower values update faster. |
| `highlightStrength` | `0.35` | Intensity of the specular highlight. Typical range: `0.0` to `0.6`. |
| `shadowStrength` | `0.18` | Opacity of the drop shadow beneath the glass. |
| `reduceTransparency` | `false` | If true, reduces blur intensity for accessibility/performance. |
| `reduceMotion` | `false` | If true, disables distortion and pointer-based parallax effects. |
| `enablePointerParallax` | `true` | Enables pointer tracking for highlights/distortion when motion is allowed. |

## Shared Blur Groups

If you place multiple glass surfaces in the same area, wrap them in `LiquidGlassGroup`
to share a single blur pass:

```dart
LiquidGlassGroup(
  child: Wrap(
    spacing: 16,
    runSpacing: 16,
    children: const [
      LiquidGlassSurface(child: Text('A')),
      LiquidGlassSurface(child: Text('B')),
    ],
  ),
);
```

## Merged Surfaces

To merge multiple glass cards into a single continuous surface, use
`LiquidGlassMergeGroup` with `LiquidGlassMergeTarget`. This mimics the native
"glass container" behavior and eliminates seams between adjacent cards.

```dart
LiquidGlassMergeGroup(
  child: Wrap(
    spacing: 16,
    runSpacing: 16,
    children: const [
      LiquidGlassMergeTarget(
        child: Text('A'),
      ),
      LiquidGlassMergeTarget(
        child: Text('B'),
      ),
      LiquidGlassMergeTarget(
        child: Text('C'),
      ),
    ],
  ),
);
```

Each `LiquidGlassMergeTarget` can specify its own `borderRadius` and `padding`
to control the merged outline.

## Foreground Styling

Use `LiquidGlassForeground` to automatically choose a readable text/icon color
based on the resolved glass brightness:

```dart
LiquidGlassSurface(
  child: const LiquidGlassForeground(
    child: Text('Readable on Glass'),
  ),
);
```

## Notes

- `LiquidGlassAppRoot` tracks pointer position and provides a repaint boundary
  required for adaptive tint sampling.
- Use `reduceTransparency` or `reduceMotion` in `LiquidGlassConfig` to respect
  accessibility preferences.

## Example

Run the demo app under `example/` for a complete showcase.
