import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hover_cursor.dart';
import '../../../main.dart';
import '../../../models/bank.dart';
import '../../../models/tax_mode.dart';
import '../../../models/transaction.dart';

/// Компактная сводка по одному подключённому банку — белая карточка с
/// единой акцентной рамкой AppColors.accent (не второй зелёный градиент —
/// по гайдлайну на экране допустим только один крупный AppGradients.primary).
/// Фирменный цвет банка используется только в лого-кружке
/// ([_BankLogoChip]) — не в заливке/рамке карточки, чтобы карточки не
/// превращались в "светофор" из цветов разных банков.
///
/// Показывает доход/расход по операциям этого банка и ОЦЕНОЧНЫЙ "налог с
/// банка" (см. AppState.taxResultForTransactions) — налог в РФ считается
/// на весь бизнес целиком, а не по банкам отдельно, поэтому это пересчёт
/// налога по операциям только этого банка тем же режимом/ставками, а не
/// отдельное юридическое обязательство; сумма по всем банкам может не
/// совпасть с общим налогом на главной карточке. Срок оплаты, взносы,
/// патент, НДС, НДФЛ сверх лимита НПД и бейдж режима сюда не дублируются —
/// эти детали показываются один раз, на главной карточке (TaxSummaryCard).
/// На ПСН налог всегда 0 (как и на главной карточке) — стоимость патента
/// фиксирована и не зависит от того, через какой банк прошли операции.
class BankSummaryCard extends StatelessWidget {
  final AppState state;
  final ConnectedBank bank;
  const BankSummaryCard({super.key, required this.state, required this.bank});

  Bank get _brand => kSupportedBanks.firstWhere(
    (b) => b.id == bank.bankId,
    orElse: () => Bank(id: bank.bankId, name: bank.bankName, color: AppColors.accent),
  );

  @override
  Widget build(BuildContext context) {
    final brand = _brand;

    final bankTxs = state.selectedPeriodTxs
        .where((t) => t.bankName == bank.bankName)
        .toList();
    final income = bankTxs
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final expenses = bankTxs
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    // ПСН — фиксированная стоимость патента, она не зависит от дохода и не
    // может быть отнесена к конкретному банку (см. класс-докстринг), так
    // же, как heroTax на главной карточке всегда 0 для ПСН.
    final isPsn = state.taxMode == TaxMode.psn;
    final tax = isPsn ? 0.0 : state.taxResultForTransactions(bankTxs).netTax;

    return Container(
      width: double.infinity,
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
              _BankLogoChip(color: brand.color, name: bank.bankName),
              const SizedBox(width: AppSpacing.sp12),
              Expanded(
                child: Text(
                  bank.bankName,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sp8),
              HoverCursor(
                child: GestureDetector(
                  onTap: () {
                    // Догенерирует счета, если банк был подключён до
                    // появления этой фичи и остался без них (см.
                    // AppState.ensureAccountsForBank) — вызывается из
                    // обработчика тапа, а не из build(), чтобы
                    // notifyListeners() не сработал во время построения
                    // дерева виджетов.
                    state.ensureAccountsForBank(bank.bankId);
                    Navigator.pushNamed(
                      context,
                      '/bank-accounts',
                      arguments: bank,
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Подробнее',
                        style: AppTextStyles.captionBold.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sp20),

          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: 'Налог с банка',
                  value: tax.rub,
                  color: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: 'Доход',
                  value: income.rub,
                  color: AppColors.positive,
                ),
              ),
              Expanded(
                child: _StatColumn(
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

class _BankLogoChip extends StatelessWidget {
  final Color color;
  final String name;
  const _BankLogoChip({required this.color, required this.name});

  @override
  Widget build(BuildContext context) {
    // Достаточно тёмный фирменный цвет — белая буква поверх сплошной
    // заливки; светлые (жёлтые) — тёмная буква поверх мягкой заливки,
    // иначе текст нечитаем (см. правило контраста в CLAUDE-скилле).
    final isLight = color.computeLuminance() > 0.6;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isLight ? color.withValues(alpha: 0.25) : color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
        style: AppTextStyles.captionBold.copyWith(
          color: isLight ? AppColors.textPrimary : AppColors.onAccent,
        ),
      ),
    );
  }
}

// Одна из трёх равных колонок — метка (labelSmall, ЗАГЛАВНЫМИ) + сумма
// (amountSmall) — Налог с банка/Доход/Расход рядом друг с другом одного
// размера.
class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatColumn({
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
          style: AppTextStyles.amountSmall.copyWith(color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
