import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'payment_line.dart';

/// Dashboard "variant 1" hero card — the design the user picked.
/// Bold gradient card showing: period label, big tax amount, deadline +
/// progress bar, income/expense split, and a stack of PaymentLine rows.
///
/// This is a heroic, high-contrast treatment: use it as the dashboard's
/// single most prominent element (matches the original Flutter app's
/// "TaxSummaryCard" role, just re-skinned to the light green palette).
class TaxSummaryCard extends StatelessWidget {
  final String periodLabel; // "Налог к уплате · II квартал 2026"
  final String amount; // "148 320 ₽"
  final String dueDateLabel; // "Срок оплаты: 28 июля 2026"
  final String daysLeftLabel; // "19 дней"
  final double progress; // 0..1, elapsed share of the payment window
  final String income; // "1 240 000 ₽"
  final String expense; // "812 500 ₽"
  final List<MapEntry<String, String>> paymentLines; // e.g. [("НДФЛ (13%)", "55 575 ₽"), ...]

  const TaxSummaryCard({
    super.key,
    required this.periodLabel,
    required this.amount,
    required this.dueDateLabel,
    required this.daysLeftLabel,
    required this.progress,
    required this.income,
    required this.expense,
    required this.paymentLines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            periodLabel.toUpperCase(),
            style: TextStyle(
              color: AppColors.onGradientAlpha(0.75),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 10),
          Text(amount, style: AppTextStyles.amount.copyWith(color: AppColors.onGradient)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dueDateLabel,
                style: TextStyle(color: AppColors.onGradientAlpha(0.9), fontSize: 13, fontFamily: 'Inter'),
              ),
              Text(
                daysLeftLabel,
                style: TextStyle(
                  color: AppColors.onGradientAlpha(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.onGradientAlpha(AppColors.fillOnGradient22),
              valueColor: AlwaysStoppedAnimation(AppColors.onGradient),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.onGradientAlpha(0.18), height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(label: 'Доход', value: income),
              _MiniStat(label: 'Расход', value: expense),
            ],
          ),
          const SizedBox(height: 16),
          ...paymentLines.map((e) => PaymentLine(label: e.key, value: e.value)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.onGradientAlpha(0.7), fontSize: 11.5, fontFamily: 'Inter')),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: AppColors.onGradient, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'JetBrainsMono'),
        ),
      ],
    );
  }
}
