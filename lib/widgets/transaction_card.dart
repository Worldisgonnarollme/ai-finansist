import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../main.dart';

class TransactionCard extends StatelessWidget {
  final Transaction tx;
  const TransactionCard({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isIncome = tx.isIncome;
    final isExpense = tx.type == TransactionType.expense;

    final color = isIncome
        ? scheme.secondary
        : isExpense
            ? scheme.error
            : scheme.onSurfaceVariant;

    return Card(
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Accent bar on left
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_icon(tx.type), color: color, size: 19),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: scheme.onSurface),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                _dateStr(tx.date),
                                style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 12),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tx.type.label,
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (tx.bankName != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  tx.bankName!.split(' ').first,
                                  style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 11),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${isIncome ? '+' : '−'}${tx.amount.rub}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: color),
                    ),
                  ],
                ),
              ),
            ),
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
      case TransactionType.unknown:
        return Icons.help_outline_rounded;
    }
  }

  String _dateStr(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
