import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/ru_plural.dart';
import '../core/widgets/bordered_section_card.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/hover_cursor.dart';
import '../main.dart';
import '../models/bank.dart';
import '../models/tax_period.dart';
import '../models/transaction.dart';

/// Помесячная история операций и налогов (см. history_statements_prompt).
/// Без AppBar — заголовок обычным текстом в скролле, как на "Настройках".
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final periods = state.periods;
    // См. комментарий в main_screen.dart: на десктопе боковая панель, а не
    // плавающая пилюля — паддинг статичный. На телефоне пилюля "плавает"
    // поверх контента, нужный отступ уже учтён Scaffold.
    final isDesktop = MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
    final bottomPadding = isDesktop
        ? AppSpacing.sp32
        : MediaQuery.paddingOf(context).bottom + AppSpacing.sp16;

    return Scaffold(
      backgroundColor: AppColors.onbBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.onbGreen,
          backgroundColor: AppColors.onbCard,
          onRefresh: state.hasBanks ? state.refreshData : () async {},
          // Паддинг — на всю ширину скролла, а не внутри ограниченной
          // maxWidth-колонки, иначе он "съедает" часть 1040 — см. §
          // settings.dart (тот же приём, тот же порог 1000).
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1000;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  compact ? AppSpacing.sp16 : AppSpacing.sp48,
                  compact ? AppSpacing.sp16 + 2 : AppSpacing.sp32 + 4,
                  compact ? AppSpacing.sp16 : AppSpacing.sp48,
                  bottomPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(compact: compact),
                        SizedBox(height: compact ? AppSpacing.sp16 - 2 : AppSpacing.sp24),
                        if (periods.isEmpty)
                          EmptyState(
                            icon: Icons.history_rounded,
                            title: 'Нет данных',
                            subtitle: 'Подключите банк или добавьте\nоперации вручную',
                            action: FilledButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/add-tx'),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Добавить операцию'),
                            ),
                          )
                        else ...[
                          if (state.hasBanks) ...[
                            BorderedSectionCard(
                              title: 'Подключённые банки',
                              children: [
                                for (final bank in state.connectedBanks)
                                  _BankRow(state: state, bank: bank),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sp16),
                          ],
                          BorderedSectionCard(
                            title: 'Операции по месяцам',
                            children: [
                              for (int i = 0; i < periods.length; i++)
                                _MonthRow(period: periods[i])
                                    .animate(delay: (i * 45).ms)
                                    .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Раскладка — точная копия _Pagehead из settings.dart: Row (титул слева,
// подпись справа, общая базовая линия) на desktop, Column на mobile —
// чтобы заголовки экранов совпадали по положению и высоте шапки.
class _Header extends StatelessWidget {
  final bool compact;
  const _Header({required this.compact});

  @override
  Widget build(BuildContext context) {
    final title = Text('История', style: AppTextStyles.historyH1);
    final sub = Text(
      'Помесячная история операций и налогов',
      style: AppTextStyles.historySub,
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 4), sub],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [title, sub],
    );
  }
}

// Строка подключённого банка — визуально в языке экрана "История"
// (тот же icon-chip/Wrap-паттерн, что и у _FileRow на экране "Выписки").
// Доход/расход — по ВСЕМ операциям банка (не только за текущий период, в
// отличие от главного экрана) — по нажатию открывается разбивка по счетам
// (BankAccountsScreen, см. AppState.ensureAccountsForBank).
class _BankRow extends StatelessWidget {
  final AppState state;
  final ConnectedBank bank;
  const _BankRow({required this.state, required this.bank});

  Color get _brandColor => kSupportedBanks
      .firstWhere(
        (b) => b.id == bank.bankId,
        orElse: () => Bank(id: bank.bankId, name: bank.bankName, color: AppColors.onbGreen),
      )
      .color;

  @override
  Widget build(BuildContext context) {
    final brandColor = _brandColor;
    final bankTxs = state.transactions.where((t) => t.bankName == bank.bankName);
    final income = bankTxs.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final expenses = bankTxs
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final accountsCount = state.accountsForBank(bank.bankId).length;

    return HoverCursor(
      child: GestureDetector(
        onTap: () {
          // Догенерирует счета, если банк подключён давно и остался без
          // них (см. AppState.ensureAccountsForBank) — вызывается из
          // обработчика тапа, а не из build().
          state.ensureAccountsForBank(bank.bankId);
          Navigator.pushNamed(context, '/bank-accounts', arguments: bank);
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp16 + 2,
            vertical: AppSpacing.sp12 + 1,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.account_balance_rounded,
                  size: 17,
                  color: brandColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sp12 + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank.bankName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.historyRowTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ruAccounts(accountsCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.historyRowSubtitle,
                    ),
                    const SizedBox(height: AppSpacing.sp4 + 2),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Доходы ${income.rub}',
                          style: AppTextStyles.historyInlineAmount.copyWith(
                            color: AppColors.onbGreen,
                          ),
                        ),
                        Text(
                          'Расходы ${expenses.rub}',
                          style: AppTextStyles.historyInlineAmount.copyWith(
                            color: AppColors.onbOrangeText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sp8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 15,
                color: AppColors.onbInkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  final TaxPeriod period;
  const _MonthRow({required this.period});

  @override
  Widget build(BuildContext context) {
    return HoverCursor(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(
          context,
          '/period',
          arguments: {'year': period.year, 'month': period.month},
        ),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp16 + 2,
            vertical: AppSpacing.sp12 + 1,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.onbGreenSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.calendar_today_rounded,
                  size: 17,
                  color: AppColors.onbGreen,
                ),
              ),
              const SizedBox(width: AppSpacing.sp12 + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.historyRowTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ruOperations(period.transactionCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.historyRowSubtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sp8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sp8 + 2,
                        vertical: AppSpacing.sp4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.onbOrangeSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          period.tax.rub,
                          maxLines: 1,
                          style: AppTextStyles.historyPillValue.copyWith(
                            color: AppColors.onbOrangeText,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sp4 + 2),
                  const Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.onbInkSoft),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
