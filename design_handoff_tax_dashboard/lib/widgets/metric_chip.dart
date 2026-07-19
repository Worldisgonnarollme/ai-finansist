import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

/// "Доходы" / "Расходы" pair shown right under the hero card.
/// Green for income, rust for expense — the only two semantic colors
/// besides the neutral text scale.
class MetricChip extends StatelessWidget {
  final String label; // "Доходы" | "Расходы"
  final String value; // formatted amount, e.g. "1 240 000 ₽"
  final bool isPositive; // true = income (green), false = expense (rust)

  const MetricChip({super.key, required this.label, required this.value, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.positive : AppColors.negative;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16 - 2, vertical: AppSpacing.sp12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 12,
                color: color,
              ),
              const SizedBox(width: 5),
              Text(
                label.toUpperCase(),
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.amountSmall.copyWith(color: color, fontSize: 18)),
        ],
      ),
    );
  }
}
