import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

enum OnbChipStyle { green, orange, glass }

/// Пилюля-чип онбординга — три варианта ровно как в HTML-прототипе
/// (docs/design/onboarding_*_concept.html): зелёный/оранжевый — плоская
/// мягкая заливка, glass — полупрозрачная белая подложка с блюром.
class OnbChip extends StatelessWidget {
  final String label;
  final OnbChipStyle style;
  final IconData? icon;

  const OnbChip({
    super.key,
    required this.label,
    this.style = OnbChipStyle.green,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    switch (style) {
      case OnbChipStyle.green:
        fg = AppColors.onbGreen;
        bg = AppColors.onbGreenSoft;
      case OnbChipStyle.orange:
        fg = AppColors.onbOrangeText;
        bg = AppColors.onbOrangeSoft;
      case OnbChipStyle.glass:
        fg = AppColors.onbGreenDeep;
        bg = AppColors.onbCard.withValues(alpha: 0.65);
    }

    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp12,
        vertical: AppSpacing.sp8 - 1,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 6),
          ] else ...[
            Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: fg)),
            const SizedBox(width: 6),
          ],
          Text(label, style: AppTextStyles.captionBold.copyWith(color: fg)),
        ],
      ),
    );

    if (style != OnbChipStyle.glass) return content;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: content,
      ),
    );
  }
}
