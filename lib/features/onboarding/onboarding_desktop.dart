import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import 'data/onboarding_steps.dart';
import 'widgets/onb_chip.dart';
import 'widgets/onboarding_cta.dart';
import 'widgets/onboarding_scene.dart';
import 'widgets/onboarding_stepper.dart';

/// Десктопная композиция онбординга — сцена 55% слева, контент 45%
/// справа, навигация — кликабельный степпер + клавиатура ←/→ (§6 скилла).
class OnboardingDesktop extends StatelessWidget {
  final int step;
  final ValueChanged<int> onShow;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const OnboardingDesktop({
    super.key,
    required this.step,
    required this.onShow,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final data = onboardingSteps[step];
    final isLast = step == onboardingSteps.length - 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sp48,
            AppSpacing.sp24 + 4,
            AppSpacing.sp48,
            0,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(AppRadius.sm - 1),
                ),
                child: Text(
                  '₽',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onAccent, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: AppSpacing.sp8 + 2),
              Text('AI-Финансист', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800, color: AppColors.onbInk)),
              const Spacer(),
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.onbInkSoft,
                  textStyle: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
                child: const Text('Пропустить'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sp48,
                  AppSpacing.sp24,
                  AppSpacing.sp48,
                  AppSpacing.sp48,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 55,
                      child: OnboardingScene(
                        step: step,
                        isWide: true,
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sp48 + AppSpacing.sp8),
                    Expanded(
                      flex: 45,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: OnbChip(
                                  key: ValueKey('chip$step'),
                                  label: data.chip,
                                  style: data.chipOrange ? OnbChipStyle.orange : OnbChipStyle.green,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sp24 - 2),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Text.rich(
                                  TextSpan(children: [
                                    TextSpan(text: data.title),
                                    TextSpan(text: data.accent, style: const TextStyle(color: AppColors.onbGreen)),
                                  ]),
                                  key: ValueKey('title$step'),
                                  style: AppTextStyles.onbHeadline.copyWith(fontSize: 46),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sp16 + 2),
                              ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: 82),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: Text(
                                    data.desc,
                                    key: ValueKey('desc$step'),
                                    style: AppTextStyles.onbDesc.copyWith(fontSize: 17),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sp32 + 4),
                              OnboardingStepper(current: step, onTap: onShow),
                              const SizedBox(height: AppSpacing.sp32),
                              OnboardingCta(label: isLast ? 'Начать' : 'Далее', onPressed: onNext),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
