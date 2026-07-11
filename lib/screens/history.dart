import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/empty_state.dart';
import '../main.dart';
import '../models/tax_period.dart';
import '../widgets/responsive_page.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final periods = state.periods;
    // На десктопе внизу боковая панель, а не плавающая пилюля — паддинг
    // остаётся прежним статичным значением. На телефоне/узком окне пилюля
    // "плавает" поверх контента (MainScreen.extendBody) — нужный отступ
    // Scaffold уже прибавил к MediaQuery.paddingOf(context).bottom сам.
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
    final bottomPadding = isDesktop
        ? AppSpacing.sp32
        : MediaQuery.paddingOf(context).bottom + AppSpacing.sp16;

    return Scaffold(
      appBar: AppBar(
        title: Text('История', style: AppTextStyles.headlineMedium),
      ),
      body: SafeArea(
        // bottom: false — см. комментарий в dashboard.dart: нижний отступ
        // под пилюлю считает сам bottomPadding, а не эта SafeArea.
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surfaceAlt,
          onRefresh: state.hasBanks ? state.refreshData : () async {},
          child: ResponsivePage(
            child: periods.isEmpty
                ? ListView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.sp16,
                      0,
                      AppSpacing.sp16,
                      bottomPadding,
                    ),
                    children: [
                      EmptyState(
                        icon: Icons.history_rounded,
                        title: 'Нет данных',
                        subtitle: 'Подключите банк или добавьте\nоперации вручную',
                        action: FilledButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/add-tx'),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Добавить операцию'),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.sp16,
                      AppSpacing.sp8,
                      AppSpacing.sp16,
                      bottomPadding,
                    ),
                    itemCount: periods.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sp12),
                    itemBuilder: (_, i) {
                      final p = periods[i];
                      // Каскадное появление: каждая следующая карточка
                      // стартует на 45мс позже предыдущей, с лёгким
                      // слайдом снизу — задаёт ощущение списка, а не
                      // рассинхронизированного мигания всех строк разом.
                      return _PeriodCard(
                            period: p,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/period',
                              arguments: {'year': p.year, 'month': p.month},
                            ),
                          )
                          .animate(delay: (i * 45).ms)
                          .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
                          .slideY(
                            begin: 0.1,
                            end: 0,
                            duration: 300.ms,
                            curve: Curves.easeOutCubic,
                          );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final TaxPeriod period;
  final VoidCallback onTap;
  const _PeriodCard({required this.period, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sp16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    period.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${period.transactionCount} опер.',
                  style: AppTextStyles.labelSmall,
                ),
                const SizedBox(width: AppSpacing.sp4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sp16),
            Row(
              children: [
                Flexible(
                  child: _Stat(
                    label: 'Налог',
                    value: period.tax.rub,
                    color: AppColors.warning,
                  ),
                ),
                if (period.insurance > 0) ...[
                  const SizedBox(width: AppSpacing.sp24),
                  // Взносы — отдельный от налога обязательный платёж,
                  // поэтому отдельная колонка, а не часть суммы налога.
                  Flexible(
                    child: _Stat(
                      label: 'Взносы',
                      value: period.insurance.rub,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
                const Spacer(),
                Flexible(
                  child: _Stat(
                    label: 'Доход',
                    value: period.income.rub,
                    color: AppColors.positive,
                  ),
                ),
                const SizedBox(width: AppSpacing.sp24),
                Flexible(
                  child: _Stat(
                    label: 'Расход',
                    value: period.expenses.rub,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            if (period.income > 0) ...[
              const SizedBox(height: AppSpacing.sp16),
              _TaxRatioBar(income: period.income, tax: period.tax),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaxRatioBar extends StatelessWidget {
  final double income;
  final double tax;
  const _TaxRatioBar({required this.income, required this.tax});

  @override
  Widget build(BuildContext context) {
    final ratio = (tax / income).clamp(0.0, 1.0);
    final pct = (ratio * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Налоговая нагрузка', style: AppTextStyles.labelSmall),
            Text(
              '$pct%',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sp8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.divider,
            color: AppColors.accent,
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.sp4),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
