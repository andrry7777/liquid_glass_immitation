import 'package:flutter/material.dart';
import 'package:glass_like_surface/glass_like_surface.dart';

void main() {
  runApp(const GlassLikeSurfaceDemoApp());
}

class GlassLikeSurfaceDemoApp extends StatefulWidget {
  const GlassLikeSurfaceDemoApp({super.key});

  @override
  State<GlassLikeSurfaceDemoApp> createState() =>
      _GlassLikeSurfaceDemoAppState();
}

class _GlassLikeSurfaceDemoAppState extends State<GlassLikeSurfaceDemoApp> {
  double _blurSigma = 20;
  double _distortionStrength = 0.03;
  bool _adaptiveTint = false;
  bool _reduceMotion = false;

  GlassLikeSurfaceConfig get _config => GlassLikeSurfaceConfig(
        blurSigma: _blurSigma,
        distortionStrength: _distortionStrength,
        adaptiveTint: _adaptiveTint,
        reduceMotion: _reduceMotion,
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: GlassLikeSurfaceAppRoot(
        config: _config,
        child: GlassLikeSurfaceDemoPage(
          blurSigma: _blurSigma,
          distortionStrength: _distortionStrength,
          adaptiveTint: _adaptiveTint,
          reduceMotion: _reduceMotion,
          onBlurSigmaChanged: (value) => setState(() => _blurSigma = value),
          onDistortionStrengthChanged: (value) =>
              setState(() => _distortionStrength = value),
          onAdaptiveTintChanged: (value) =>
              setState(() => _adaptiveTint = value),
          onReduceMotionChanged: (value) =>
              setState(() => _reduceMotion = value),
        ),
      ),
    );
  }
}

class GlassLikeSurfaceDemoPage extends StatelessWidget {
  const GlassLikeSurfaceDemoPage({
    super.key,
    required this.blurSigma,
    required this.distortionStrength,
    required this.adaptiveTint,
    required this.reduceMotion,
    required this.onBlurSigmaChanged,
    required this.onDistortionStrengthChanged,
    required this.onAdaptiveTintChanged,
    required this.onReduceMotionChanged,
  });

  final double blurSigma;
  final double distortionStrength;
  final bool adaptiveTint;
  final bool reduceMotion;
  final ValueChanged<double> onBlurSigmaChanged;
  final ValueChanged<double> onDistortionStrengthChanged;
  final ValueChanged<bool> onAdaptiveTintChanged;
  final ValueChanged<bool> onReduceMotionChanged;

  GlassLikeSurfaceConfig get _config => GlassLikeSurfaceConfig(
        blurSigma: blurSigma,
        distortionStrength: distortionStrength,
        adaptiveTint: adaptiveTint,
        reduceMotion: reduceMotion,
      );

  @override
  Widget build(BuildContext context) {
    void showDemoDialog() {
      showGlassLikeSurfaceDialog<void>(
        context: context,
        builder: (context) => GlassLikeSurfaceDialog(
          config: _config,
          title: const Text('Session expired'),
          content: const Text('Please sign in again to continue.'),
          actions: [
            GlassLikeSurfaceDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            GlassLikeSurfaceDialogAction(
              isDefaultAction: true,
              child: const Text('Sign in'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Glass Demo',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Adjust the sliders to see blur and refraction change in real time.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  GlassLikeSurface(
                    config: _config,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Controls',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        _LabeledSlider(
                          label: 'Blur sigma',
                          value: blurSigma,
                          min: 4,
                          max: 40,
                          onChanged: onBlurSigmaChanged,
                        ),
                        const SizedBox(height: 8),
                        _LabeledSlider(
                          label: 'Distortion strength',
                          value: distortionStrength,
                          min: 0,
                          max: 0.08,
                          onChanged: onDistortionStrengthChanged,
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: adaptiveTint,
                          title: const Text('Adaptive tint'),
                          onChanged: onAdaptiveTintChanged,
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: reduceMotion,
                          title: const Text('Reduce motion'),
                          onChanged: onReduceMotionChanged,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const GlassLikeSurfaceGroup(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _MetricCard(title: 'Focus', value: '84%'),
                        _MetricCard(title: 'Flow', value: '2.4x'),
                        _MetricCard(title: 'Pulse', value: '118'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GlassLikeSurface(
                    config: _config,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Highlights',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Move the pointer or scroll to see the lighting respond to motion.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {},
                                child: const Text('Primary'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {},
                                child: const Text('Secondary'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: showDemoDialog,
                            child: const Text('Show dialog'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF111725),
            Color(0xFF251E3E),
            Color(0xFF2F3C5C),
            Color(0xFF0F1B2A),
          ],
        ),
      ),
      child: Stack(
        children: [
          _Bubble(
            alignment: Alignment(-0.8, -0.7),
            color: Color(0xFF7C4DFF),
            size: 220,
          ),
          _Bubble(
            alignment: Alignment(0.9, -0.4),
            color: Color(0xFF00E5FF),
            size: 180,
          ),
          _Bubble(
            alignment: Alignment(-0.2, 0.6),
            color: Color(0xFFFF8A80),
            size: 260,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.alignment,
    required this.color,
    required this.size,
  });

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.45),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 60,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: GlassLikeSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const GlassLikeSurfaceForeground(
              child: Text('Live update'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(value.toStringAsFixed(2)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
