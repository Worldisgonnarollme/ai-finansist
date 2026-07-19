import 'package:flutter/material.dart';

/// Тонкая шумовая текстура поверх сцены онбординга — файловый PNG,
/// не шейдер/CustomPainter (стабильнее и дешевле, особенно в Web), см.
/// .claude/skills/flutter-onboarding-green-orange, §4.
class GrainOverlay extends StatelessWidget {
  final double opacity;

  const GrainOverlay({super.key, this.opacity = 0.12});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: const Image(
            image: AssetImage('assets/images/noise.png'),
            repeat: ImageRepeat.repeat,
            fit: BoxFit.none,
            alignment: Alignment.topLeft,
          ),
        ),
      ),
    );
  }
}
