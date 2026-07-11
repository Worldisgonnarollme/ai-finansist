import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/transaction.dart';
import '../models/tax_mode.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../main.dart';
import '../services/tax_calculator.dart';
import '../features/transactions/widgets/transaction_tile.dart';
import '../features/transactions/widgets/month_header.dart';
import '../widgets/responsive_page.dart';

class PeriodDetailScreen extends StatefulWidget {
  final int year;
  final int month;
  const PeriodDetailScreen({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  State<PeriodDetailScreen> createState() => _PeriodDetailScreenState();
}

class _PeriodDetailScreenState extends State<PeriodDetailScreen> {
  String _filter = 'all';

  static const _months = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  String get _title => '${_months[widget.month - 1]} ${widget.year}';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final all = state.txsForPeriod(widget.year, widget.month);
    final txs = _filtered(all);

    final income = all
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final expenses = all
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final tax = TaxCalculator.calculateTax(all, state.taxMode);

    return Scaffold(
      appBar: AppBar(title: Text(_title, style: AppTextStyles.headlineMedium)),
      body: SafeArea(
        child: ResponsivePage(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sp16,
                  0,
                  AppSpacing.sp16,
                  AppSpacing.sp16,
                ),
                child: _SummaryCard(
                  income: income,
                  expenses: expenses,
                  tax: tax,
                  taxMode: state.taxMode.shortName,
                ),
              ),
              _FilterBar(
                selected: _filter,
                onChanged: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: AppSpacing.sp8),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppColors.surfaceAlt,
                  onRefresh: state.hasBanks ? state.refreshData : () async {},
                  child: txs.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sp16,
                          ),
                          children: const [_Empty()],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.sp16,
                            0,
                            AppSpacing.sp16,
                            AppSpacing.sp32,
                          ),
                          itemCount: txs.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sp8),
                          itemBuilder: (_, i) => TransactionTile(tx: txs[i])
                              .animate(delay: (i * 45).ms)
                              .fadeIn(
                                duration: 300.ms,
                                curve: Curves.easeOutCubic,
                              )
                              .slideY(
                                begin: 0.1,
                                end: 0,
                                duration: 300.ms,
                                curve: Curves.easeOutCubic,
                              ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Transaction> _filtered(List<Transaction> txs) {
    switch (_filter) {
      case 'income':
        return txs.where((t) => t.isIncome).toList();
      case 'expense':
        return txs.where((t) => t.type == TransactionType.expense).toList();
      default:
        return txs;
    }
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.sp12),
          Text('Нет операций за этот период', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double income;
  final double expenses;
  final double tax;
  final String taxMode;
  const _SummaryCard({
    required this.income,
    required this.expenses,
    required this.tax,
    required this.taxMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonthHeader(
            label: 'Налог за период',
            total: tax.rub,
            totalColor: AppColors.accent,
          ),
          const SizedBox(height: AppSpacing.sp16),
          Row(
            children: [
              Flexible(
                child: _Item(
                  label: 'Доход',
                  value: income.rub,
                  color: AppColors.positive,
                ),
              ),
              const SizedBox(width: AppSpacing.sp24),
              Flexible(
                child: _Item(
                  label: 'Расходы',
                  value: expenses.rub,
                  color: AppColors.negative,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp12,
                  vertical: AppSpacing.sp4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  taxMode,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Item({required this.label, required this.value, required this.color});

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

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
      child: Row(
        children: [
          _Chip(
            label: 'Все',
            value: 'all',
            selected: selected,
            onTap: onChanged,
          ),
          const SizedBox(width: AppSpacing.sp8),
          _Chip(
            label: 'Доходы',
            value: 'income',
            selected: selected,
            onTap: onChanged,
          ),
          const SizedBox(width: AppSpacing.sp8),
          _Chip(
            label: 'Расходы',
            value: 'expense',
            selected: selected,
            onTap: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;
  const _Chip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp16,
          vertical: AppSpacing.sp8 - 1,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: active ? null : Border.all(color: AppColors.divider),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: active ? AppColors.onAccent : AppColors.textSecondary,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
