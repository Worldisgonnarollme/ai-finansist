import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import 'grain_overlay.dart';
import 'scene_ai_cards.dart';
import 'scene_banks_cards.dart';
import 'scene_tax_cards.dart';

/// Сцена онбординга — общий виджет для mobile и desktop (§4 скилла).
/// Слои снизу вверх: фон, орб, зерно, кольца, карточки шага.
class OnboardingScene extends StatelessWidget {
  final int step;
  final bool isWide;
  final BorderRadius borderRadius;

  const OnboardingScene({
    super.key,
    required this.step,
    required this.isWide,
    required this.borderRadius,
  });

  static const _orbAlign = [
    Alignment(0.0, 0.0),
    Alignment(0.16, -0.16),
    Alignment(-0.16, 0.16),
  ];
  static const _orbScale = [1.0, 1.06, 0.96];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        decoration: const BoxDecoration(gradient: AppGradients.onbSceneBg),
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              alignment: _orbAlign[step],
              child: AnimatedScale(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                scale: _orbScale[step],
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: isWide ? 8 : 6, sigmaY: isWide ? 8 : 6),
                  child: Container(
                    width: isWide ? 340 : 260,
                    height: isWide ? 340 : 260,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.onbOrb,
                    ),
                  ),
                ),
              ),
            ),
            const GrainOverlay(),
            Positioned.fill(child: CustomPaint(painter: _RingsPainter())),
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: _SceneCards(key: ValueKey(step), step: step, isWide: isWide),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneCards extends StatelessWidget {
  final int step;
  final bool isWide;

  const _SceneCards({super.key, required this.step, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final cards = switch (step) {
          0 => sceneTaxCards(w: w, h: h, isWide: isWide),
          1 => sceneAiCards(w: w, h: h, isWide: isWide),
          _ => sceneBanksCards(w: w, h: h, isWide: isWide),
        };
        return Stack(children: cards);
      },
    );
  }
}

/// Три концентрические окружности, stroke 1, onbGreen 12% — база
/// mobile 390×456 (радиусы 110/160/215), desktop 700×640 (170/240/310),
/// масштабируется пропорционально фактическому размеру сцены (§4 скилла).
class _RingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onbGreen.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width / 2, size.height / 2);
    final base = size.shortestSide;
    for (final fraction in const [0.34, 0.48, 0.62]) {
      canvas.drawCircle(center, base * fraction, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
