import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../widgets/period_card.dart';

/// "История" tab — list of monthly PeriodCards, newest first.
class HistoryScreen extends StatelessWidget {
  final void Function(String month) onOpenPeriod;
  const HistoryScreen({super.key, required this.onOpenPeriod});

  static const _periods = [
    (month: 'Июнь 2026', income: '1 240 000 ₽', tax: '148 320 ₽', contributions: '0 ₽', count: 24, ratio: 12),
    (month: 'Май 2026', income: '980 000 ₽', tax: '112 400 ₽', contributions: '11 500 ₽', count: 19, ratio: 11),
    (month: 'Апрель 2026', income: '1 105 000 ₽', tax: '126 900 ₽', contributions: '0 ₽', count: 21, ratio: 11),
    (month: 'Март 2026', income: '860 000 ₽', tax: '98 300 ₽', contributions: '11 500 ₽', count: 17, ratio: 11),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('История операций', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ),
            for (final p in _periods)
              PeriodCard(
                month: p.month,
                income: p.income,
                tax: p.tax,
                contributions: p.contributions,
                count: p.count,
                ratioPercent: p.ratio,
                onTap: () => onOpenPeriod(p.month),
              ),
          ],
        ),
      ),
    );
  }
}
