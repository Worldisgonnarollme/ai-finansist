import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_theme.dart';

/// Mobile-индикатор шага — точки 7×7, активная растягивается до 26px
/// с градиентом onbProgress (§5 скилла).
class OnboardingDots extends StatelessWidget {
  final int count;
  final int current;

  const OnboardingDots({super.key, required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sp4 - 1),
          width: active ? 26 : 7,
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            color: active ? null : AppColors.onbLine,
            gradient: active ? AppGradients.onbProgress : null,
          ),
        );
      }),
    );
  }
}
