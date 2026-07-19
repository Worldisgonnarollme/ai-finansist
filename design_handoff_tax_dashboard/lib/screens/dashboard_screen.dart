import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../widgets/tax_summary_card.dart';
import '../widgets/metric_chip.dart';
import '../widgets/warning_banner.dart';
import '../widgets/advice_card.dart';
import '../widgets/transaction_tile.dart';

/// Example assembly of the Dashboard ("Главная") tab using the widgets in
/// this package — reproduces the chosen variant-1 design 1:1, wired to
/// static sample data matching the prototype. Wire this up to your real
/// tax-calculation state before merging.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.sp18, AppSpacing.sp8, AppSpacing.sp18, 90),
          children: [
            // Header: greeting + regime badge + avatar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Здравствуйте, Алексей', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.full)),
                      child: const Text('ИП · ОСНО', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.surface,
                  child: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Hero — variant 1 (chosen)
            const TaxSummaryCard(
              periodLabel: 'Налог к уплате · II квартал 2026',
              amount: '148 320 ₽',
              dueDateLabel: 'Срок оплаты: 28 июля 2026',
              daysLeftLabel: '19 дней',
              progress: 0.30,
              income: '1 240 000 ₽',
              expense: '812 500 ₽',
              paymentLines: [
                MapEntry('НДФЛ (13%)', '55 575 ₽'),
                MapEntry('НДС к уплате', '92 745 ₽'),
                MapEntry('Страховые взносы', 'оплачено'),
              ],
            ),
            const SizedBox(height: 14),

            // Static warning: progressive NDFL rate above 5M/year
            const WarningBanner(
              icon: Icons.warning_amber_rounded,
              text: 'Доход нарастающим итогом превысил 5 000 000 ₽ — с превышения НДФЛ '
                  'удерживается по ставке 15%.',
            ),
            const SizedBox(height: 12),

            // Tappable warning: unmarked transaction nudge
            WarningBanner(
              icon: Icons.error_outline_rounded,
              text: '1 операция не размечена — уточните категорию',
              showChevron: true,
              onTap: () {
                // TODO: navigate to PeriodDetailScreen filtered to "review"
              },
            ),
            const SizedBox(height: 16),

            // Income / expense chips
            Row(
              children: const [
                Expanded(child: MetricChip(label: 'Доходы', value: '1 240 000 ₽', isPositive: true)),
                SizedBox(width: 10),
                Expanded(child: MetricChip(label: 'Расходы', value: '812 500 ₽', isPositive: false)),
              ],
            ),
            const SizedBox(height: 14),

            // Action row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.textPrimary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    ),
                    child: const Text('Подключить банк', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    ),
                    child: const Text('+ Операция', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 6-month bar chart — swap for fl_chart in production;
            // this is a lightweight bespoke version matching the mock exactly.
            const Text('Доходы и расходы, 6 месяцев', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            _MonthlyChartPlaceholder(),
            const SizedBox(height: 14),

            const AdviceCard(
              text: 'Перейдите на УСН 15%, чтобы снизить налоговую нагрузку — расчёт '
                  'экономии в разделе «Налоговый режим».',
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Последние операции', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                TextButton(onPressed: () {}, child: const Text('Все', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 12.5))),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: const [
                  TransactionTile(tx: TransactionData(name: 'Оплата от ООО «Вектор»', date: '8 июля', amount: '+ 184 000 ₽', type: TxType.income)),
                  TransactionTile(tx: TransactionData(name: 'Аренда офиса', date: '5 июля', amount: '− 65 000 ₽', type: TxType.expense)),
                  TransactionTile(tx: TransactionData(name: 'Перевод от физ. лица', date: '3 июля', amount: '+ 42 500 ₽', type: TxType.unknown)),
                  TransactionTile(tx: TransactionData(name: 'Канцелярия и расходники', date: '1 июля', amount: '− 8 300 ₽', type: TxType.expense)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyChartPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const months = ['Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл'];
    const income = [40.0, 52.0, 58.0, 46.0, 64.0, 30.0];
    const expense = [26.0, 30.0, 34.0, 28.0, 38.0, 18.0];
    return Container(
      height: 118,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(months.length, (i) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 76,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(width: 7, height: income[i], decoration: const BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.vertical(top: Radius.circular(3)))),
                    const SizedBox(width: 2),
                    Container(width: 7, height: expense[i], decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.35), borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(months[i], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
            ],
          );
        }),
      ),
    );
  }
}
