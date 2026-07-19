import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/hover_cursor.dart';
import '../features/transactions/widgets/transaction_tile.dart';
import '../main.dart';
import '../models/bank_account.dart';
import '../models/transaction.dart';
import '../widgets/responsive_page.dart';

const _monthNamesRu = [
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

/// Операции конкретного счёта — открывается по тапу на счёт в
/// BankAccountsScreen (и из главного экрана, и из "Истории", так как обе
/// ведут на один и тот же путь). Список — за выбранный месяц (по
/// умолчанию текущий, можно листать стрелками, как в банковском
/// приложении), плюс отдельно доход/расход нарастающим итогом за год
/// этого месяца.
class AccountOperationsScreen extends StatefulWidget {
  final BankAccount account;
  const AccountOperationsScreen({super.key, required this.account});

  @override
  State<AccountOperationsScreen> createState() =>
      _AccountOperationsScreenState();
}

class _AccountOperationsScreenState extends State<AccountOperationsScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final accountTxs = state.transactions.where(
      (t) => t.accountId == widget.account.id,
    );

    final monthTxs =
        accountTxs
            .where(
              (t) => t.date.year == _month.year && t.date.month == _month.month,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final yearTxs = accountTxs.where((t) => t.date.year == _month.year);
    final yearIncome = yearTxs
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final yearExpenses = yearTxs
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account.name, style: AppTextStyles.headlineMedium),
      ),
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
                child: Column(
                  children: [
                    _YearSummary(
                      year: _month.year,
                      income: yearIncome,
                      expenses: yearExpenses,
                    ),
                    const SizedBox(height: AppSpacing.sp16),
                    _MonthNav(month: _month, onShift: _shiftMonth),
                  ],
                ),
              ),
              Expanded(
                child: monthTxs.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sp16,
                        ),
                        children: const [
                          EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'Нет операций',
                            subtitle: 'В этом месяце по счёту не было операций',
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.sp16,
                          0,
                          AppSpacing.sp16,
                          AppSpacing.sp32,
                        ),
                        itemCount: monthTxs.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sp8),
                        itemBuilder: (_, i) => TransactionTile(tx: monthTxs[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearSummary extends StatelessWidget {
  final int year;
  final double income;
  final double expenses;
  const _YearSummary({
    required this.year,
    required this.income,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('СУММАРНО ЗА $year ГОД', style: AppTextStyles.labelSmall),
          const SizedBox(height: AppSpacing.sp12),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Доход',
                  value: income.rub,
                  color: AppColors.positive,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Расход',
                  value: expenses.rub,
                  color: AppColors.negative,
                ),
              ),
            ],
          ),
        ],
      ),
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
        Text(label.toUpperCase(), style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.sp4),
        Text(
          value,
          style: AppTextStyles.amountSmall.copyWith(color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _MonthNav extends StatelessWidget {
  final DateTime month;
  final ValueChanged<int> onShift;
  const _MonthNav({required this.month, required this.onShift});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavButton(icon: Icons.chevron_left_rounded, onTap: () => onShift(-1)),
        Text(
          '${_monthNamesRu[month.month - 1]} ${month.year}',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        _NavButton(icon: Icons.chevron_right_rounded, onTap: () => onShift(1)),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HoverCursor(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.divider),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
