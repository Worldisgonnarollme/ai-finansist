import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hover_cursor.dart';
import '../../../models/transaction.dart';
import '../../transactions/widgets/transaction_tile.dart';

/// Section on the dashboard showing the last few operations, with a link
/// to the full transaction history.
class RecentTransactionsList extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback onSeeAll;

  const RecentTransactionsList({
    super.key,
    required this.transactions,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.sp4,
            bottom: AppSpacing.sp8,
          ),
          child: Row(
            children: [
              Text('ПОСЛЕДНИЕ ОПЕРАЦИИ', style: AppTextStyles.labelSmall),
              const Spacer(),
              HoverCursor(
                child: GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    'Все операции →',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (transactions.isEmpty)
          const _EmptyRecent()
        else
          ...transactions.map(
            (tx) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sp8),
              child: TransactionTile(tx: tx),
            ),
          ),
      ],
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 28,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.sp8),
          Text('Операций пока нет', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
