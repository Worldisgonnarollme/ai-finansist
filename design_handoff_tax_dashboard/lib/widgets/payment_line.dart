import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

/// A single "payment line" pill inside [TaxSummaryCard] — e.g. "НДФЛ (13%)"
/// with its amount right-aligned. Semi-transparent white fill on the
/// gradient hero (12% alpha), matching the on-gradient pattern.
class PaymentLine extends StatelessWidget {
  final String label;
  final String value;

  const PaymentLine({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sp8),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.onGradientAlpha(AppColors.fillOnGradient12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.onGradientAlpha(0.95),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            value,
            style: AppTextStyles.amountSmall.copyWith(
              color: AppColors.onGradient,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
