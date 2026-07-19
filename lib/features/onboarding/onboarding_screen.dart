import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'data/onboarding_steps.dart';
import 'onboarding_desktop.dart';
import 'onboarding_mobile.dart';

/// Точка входа онбординга — LayoutBuilder переключает mobile/desktop на
/// брейкпоинте 900 (§1 скилла flutter-onboarding-green-orange). Индекс
/// шага общий для сцены, чипа, заголовка и навигации — свайп/степпер/CTA
/// дают один и тот же переход.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _show(int i) {
    final clamped = i.clamp(0, onboardingSteps.length - 1);
    if (clamped != _step) setState(() => _step = clamped);
  }

  // ── Бизнес-логика (не трогать) ──────────────────────────────────────────

  void _next() {
    if (_step < onboardingSteps.length - 1) {
      _show(_step + 1);
    } else {
      _goToTaxMode();
    }
  }

  void _goToTaxMode() {
    context.read<AppState>().completeOnboarding();
    Navigator.pushReplacementNamed(context, '/login');
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _show(_step + 1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _show(_step - 1);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.onbBg,
        body: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _onKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= AppBreakpoints.desktop;
              return isWide
                  ? OnboardingDesktop(step: _step, onShow: _show, onNext: _next, onSkip: _goToTaxMode)
                  : OnboardingMobile(step: _step, onShow: _show, onNext: _next, onSkip: _goToTaxMode);
            },
          ),
        ),
      ),
    );
  }
}
