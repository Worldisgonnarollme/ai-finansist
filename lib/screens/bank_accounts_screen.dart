import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/hover_cursor.dart';
import '../main.dart';
import '../models/bank.dart';
import '../models/bank_account.dart';
import '../models/transaction.dart';
import '../widgets/responsive_page.dart';

/// Список счетов/карт, подключённых из конкретного банка — открывается по
/// кнопке "Подробнее" на карточке банка на главном экране. Доход/расход по
/// каждому счёту считается по операциям банка, распределённым по счетам
/// (см. AppState.ensureAccountsForBank/connectBank — реального банковского
/// API нет, привязка операции к счёту условная). Карточки — в едином
/// акцентном зелёном (не в цвете банка) — та же логика, что и у карточек
/// банков на дашборде: фирменный цвет банка не переносится на дочерние
/// элементы UI, чтобы не плодить "светофор" из цветов.
class BankAccountsScreen extends StatelessWidget {
  final ConnectedBank bank;
  const BankAccountsScreen({super.key, required this.bank});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final accounts = state.accountsForBank(bank.bankId);

    return Scaffold(
      appBar: AppBar(
        title: Text(bank.bankName, style: AppTextStyles.headlineMedium),
      ),
      body: SafeArea(
        child: ResponsivePage(
          maxWidth: 560,
          child: accounts.isEmpty
              ? ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp16,
                  ),
                  children: const [
                    EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Нет счетов',
                      subtitle: 'У этого банка пока нет подключённых счетов',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sp16,
                    AppSpacing.sp8,
                    AppSpacing.sp16,
                    AppSpacing.sp32,
                  ),
                  itemCount: accounts.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sp12),
                  itemBuilder: (_, i) {
                    final account = accounts[i];
                    final year = DateTime.now().year;
                    final accountTxs = state.transactions.where(
                      (t) => t.accountId == account.id && t.date.year == year,
                    );
                    final income = accountTxs
                        .where((t) => t.isIncome)
                        .fold(0.0, (s, t) => s + t.amount);
                    final expenses = accountTxs
                        .where((t) => t.type == TransactionType.expense)
                        .fold(0.0, (s, t) => s + t.amount);
                    return _AccountCard(
                      account: account,
                      year: year,
                      income: income,
                      expenses: expenses,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final BankAccount account;
  final int year;
  final double income;
  final double expenses;
  const _AccountCard({
    required this.account,
    required this.year,
    required this.income,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    return HoverCursor(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pushNamed(
          context,
          '/account-operations',
          arguments: account,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sp16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.account_balance_rounded,
                      size: 20,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sp12),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            account.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sp8 - 2),
                        Text(
                          account.maskedNumber,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sp8),
                  Text('за $year год', style: AppTextStyles.bodySmall),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp20),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Доход',
                      value: income.rub,
                      color: AppColors.positive,
                    ),
                  ),
                  Expanded(
                    child: _MiniStat(
                      label: 'Расход',
                      value: expenses.rub,
                      color: AppColors.negative,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.sp4),
        Text(
          value,
          style: AppTextStyles.amountSmall.copyWith(color: color, fontSize: 24),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
