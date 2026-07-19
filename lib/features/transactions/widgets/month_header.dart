import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Sticky-style header row: month name on the left, running total on the
/// right, both aligned to the spacing/typography scale.
class MonthHeader extends StatelessWidget {
  final String label;
  final String total;
  final Color? totalColor;

  const MonthHeader({
    super.key,
    required this.label,
    required this.total,
    this.totalColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label.toUpperCase(), style: AppTextStyles.labelSmall),
        ),
        Text(
          total,
          style: AppTextStyles.amountSmall.copyWith(
            color: totalColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
