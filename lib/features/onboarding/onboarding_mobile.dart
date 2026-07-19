import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import 'data/onboarding_steps.dart';
import 'widgets/onb_chip.dart';
import 'widgets/onboarding_cta.dart';
import 'widgets/onboarding_dots.dart';
import 'widgets/onboarding_scene.dart';

/// Мобильная композиция онбординга — сцена сверху 54% высоты, контент
/// снизу; навигация — свайп по сцене + точки + CTA (§5 скилла).
class OnboardingMobile extends StatelessWidget {
  final int step;
  final ValueChanged<int> onShow;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const OnboardingMobile({
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
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Column(
      children: [
        Expanded(
          flex: 54,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragEnd: (details) {
                    final v = details.primaryVelocity ?? 0;
                    if (v < -200) onShow(step + 1);
                    if (v > 200) onShow(step - 1);
                  },
                  child: OnboardingScene(
                    step: step,
                    isWide: false,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                ),
              ),
              Positioned(
                top: topInset + AppSpacing.sp8,
                right: AppSpacing.sp16 + 6,
                child: GestureDetector(
                  onTap: onSkip,
                  child: const OnbChip(label: 'Пропустить', style: OnbChipStyle.glass),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 46,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.sp24 + 2,
              AppSpacing.sp24 + 2,
              AppSpacing.sp24 + 2,
              AppSpacing.sp16 + bottomInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: OnbChip(
                    key: ValueKey('chip$step'),
                    label: data.chip,
                    style: data.chipOrange ? OnbChipStyle.orange : OnbChipStyle.green,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: data.title),
                      TextSpan(text: data.accent, style: const TextStyle(color: AppColors.onbGreen)),
                    ]),
                    key: ValueKey('title$step'),
                    style: AppTextStyles.onbHeadline,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      data.desc,
                      key: ValueKey('desc$step'),
                      style: AppTextStyles.onbDesc,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sp16 + 2),
                OnboardingDots(count: onboardingSteps.length, current: step),
                const SizedBox(height: AppSpacing.sp20),
                OnboardingCta(
                  label: isLast ? 'Начать' : 'Далее',
                  fullWidth: true,
                  onPressed: onNext,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
