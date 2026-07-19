import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum TxType { income, expense, unknown }

class TransactionData {
  final String name;
  final String date;
  final String amount; // pre-formatted with sign, e.g. "+ 184 000 ₽"
  final TxType type;
  const TransactionData({required this.name, required this.date, required this.amount, required this.type});
}

/// Recent-operations row. `unknown` type = "needs review": rust icon +
/// (in the full period-detail list) a rust left border on the row.
class TransactionTile extends StatelessWidget {
  final TransactionData tx;
  final bool showReviewBorder;
  const TransactionTile({super.key, required this.tx, this.showReviewBorder = false});

  @override
  Widget build(BuildContext context) {
    final iconBg = switch (tx.type) {
      TxType.income => AppColors.accentSoft,
      TxType.unknown => AppColors.warningSoft,
      TxType.expense => AppColors.surfaceAlt,
    };
    final amountColor = switch (tx.type) {
      TxType.income => AppColors.accent,
      TxType.unknown => AppColors.warning,
      TxType.expense => AppColors.textPrimary,
    };
    final icon = switch (tx.type) {
      TxType.income => Icons.arrow_upward_rounded,
      TxType.expense => Icons.arrow_downward_rounded,
      TxType.unknown => Icons.help_outline_rounded,
    };
    final iconColor = switch (tx.type) {
      TxType.income => AppColors.accent,
      TxType.unknown => AppColors.warning,
      TxType.expense => AppColors.textSecondary,
    };

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: showReviewBorder && tx.type == TxType.unknown ? AppColors.warning : Colors.transparent, width: 3),
          bottom: const BorderSide(color: AppColors.dividerSoft),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(tx.date, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
          Text(tx.amount, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: amountColor, fontFamily: 'JetBrainsMono')),
        ],
      ),
    );
  }
}
