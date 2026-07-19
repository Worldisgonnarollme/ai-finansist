import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Month card in History tab — income, tax, contributions, operation
/// count, and a tax/income ratio progress bar. Tap → PeriodDetailScreen.
class PeriodCard extends StatelessWidget {
  final String month; // "Июнь 2026"
  final String income; // "1 240 000 ₽"
  final String tax; // "148 320 ₽"
  final String contributions; // "0 ₽"
  final int count; // 24
  final int ratioPercent; // 0..100, tax/income share
  final VoidCallback onTap;

  const PeriodCard({
    super.key,
    required this.month,
    required this.income,
    required this.tax,
    required this.contributions,
    required this.count,
    required this.ratioPercent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sp12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(month, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(income, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent, fontFamily: 'JetBrainsMono')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Stat(label: 'Налог', value: tax),
                const SizedBox(width: 18),
                _Stat(label: 'Взносы', value: contributions),
                const SizedBox(width: 18),
                _Stat(label: 'Операций', value: '$count'),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: ratioPercent / 100,
                minHeight: 6,
                backgroundColor: AppColors.surfaceAlt,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
            const SizedBox(height: 5),
            Text('Доля налога от дохода: $ratioPercent%', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'JetBrainsMono')),
        ],
      );
}
