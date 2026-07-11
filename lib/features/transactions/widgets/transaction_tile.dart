import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../main.dart';
import '../../../models/transaction.dart';

/// A single operation row. Used in the dashboard's recent transactions list
/// and in the transaction history screen.
class TransactionTile extends StatelessWidget {
  final Transaction tx;
  const TransactionTile({super.key, required this.tx});

  bool get _needsReview => tx.type == TransactionType.unknown;

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.isIncome;
    // Доход = зелёный, расход = рыжий — везде (иконка, её фон, сумма),
    // включая круги категорий в истории операций (Этап 2/3 редизайна).
    final amountColor = _needsReview
        ? AppColors.warning
        : (isIncome ? AppColors.positive : AppColors.negative);
    final iconColor = _needsReview
        ? AppColors.warning
        : (isIncome ? AppColors.accent : AppColors.warning);
    final iconBg = _needsReview
        ? AppColors.warningSoft
        : (isIncome ? AppColors.accentSoft : AppColors.warningSoft);

    return GestureDetector(
      onTap: _needsReview ? () => _showClassifySheet(context) : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: _needsReview ? AppColors.warning : Colors.transparent,
              width: 3,
            ),
            bottom: const BorderSide(color: AppColors.dividerSoft),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp16 - 2,
          vertical: AppSpacing.sp12 + 1,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(_icon(tx.type), color: iconColor, size: 16),
            ),
            const SizedBox(width: AppSpacing.sp12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp4 - 2),
                  Row(
                    children: [
                      Text(
                        _dateStr(tx.date),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sp8),
                      Expanded(
                        child: Text(
                          _needsReview
                              ? 'Не учтено в налоге · нажмите, чтобы разметить'
                              : tx.type.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: _needsReview
                                ? AppColors.warning
                                : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sp8),
            Text(
              '${isIncome ? '+' : '−'} ${tx.amount.rub}',
              style: AppTextStyles.amountTiny.copyWith(color: amountColor),
            ),
          ],
        ),
      ),
    );
  }

  void _showClassifySheet(BuildContext context) {
    final appState = context.read<AppState>();
    const options = [
      (TransactionType.incomeIndividual, 'Доход от физлица'),
      (TransactionType.incomeLegal, 'Доход от юрлица/ИП'),
      (TransactionType.expense, 'Расход'),
      (TransactionType.transfer, 'Перевод между своими счетами'),
      (TransactionType.refund, 'Возврат средств'),
      (TransactionType.cashback, 'Кэшбэк / бонусы'),
      (TransactionType.bankInterest, 'Проценты по счёту/вкладу'),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sp16,
                AppSpacing.sp16,
                AppSpacing.sp16,
                AppSpacing.sp8,
              ),
              child: Text(
                'Чем была эта операция?',
                style: AppTextStyles.titleMedium,
              ),
            ),
            for (final o in options)
              ListTile(
                title: Text(o.$2, style: AppTextStyles.bodyMedium),
                onTap: () {
                  appState.reclassifyTransaction(tx.id, o.$1);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: AppSpacing.sp8),
          ],
        ),
      ),
    );
  }

  IconData _icon(TransactionType type) {
    switch (type) {
      case TransactionType.incomeIndividual:
        return Icons.person_rounded;
      case TransactionType.incomeLegal:
        return Icons.business_rounded;
      case TransactionType.income:
        return Icons.trending_up_rounded;
      case TransactionType.expense:
        return Icons.shopping_cart_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
      case TransactionType.refund:
        return Icons.undo_rounded;
      case TransactionType.cashback:
        return Icons.card_giftcard_rounded;
      case TransactionType.bankInterest:
        return Icons.savings_rounded;
      case TransactionType.unknown:
        return Icons.help_outline_rounded;
    }
  }

  String _dateStr(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
