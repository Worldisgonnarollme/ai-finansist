import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../widgets/transaction_tile.dart';

/// Detail view for a single month: summary row + filter chips + full
/// transaction list (with rust left-border on unreviewed rows).
class PeriodDetailScreen extends StatefulWidget {
  final String month;
  final VoidCallback onBack;
  const PeriodDetailScreen({super.key, required this.month, required this.onBack});

  @override
  State<PeriodDetailScreen> createState() => _PeriodDetailScreenState();
}

class _PeriodDetailScreenState extends State<PeriodDetailScreen> {
  int _filter = 0; // 0 = Все, 1 = Доход, 2 = Требует внимания

  static const _allTx = [
    TransactionData(name: 'Оплата от ООО «Вектор»', date: '8 июля', amount: '+ 184 000 ₽', type: TxType.income),
    TransactionData(name: 'Аренда офиса', date: '5 июля', amount: '− 65 000 ₽', type: TxType.expense),
    TransactionData(name: 'Перевод от физ. лица', date: '3 июля', amount: '+ 42 500 ₽', type: TxType.unknown),
    TransactionData(name: 'Канцелярия и расходники', date: '1 июля', amount: '− 8 300 ₽', type: TxType.expense),
    TransactionData(name: 'Поставка материалов', date: '28 июня', amount: '− 121 400 ₽', type: TxType.expense),
    TransactionData(name: 'Оплата от ИП Смирнова', date: '24 июня', amount: '+ 96 000 ₽', type: TxType.income),
  ];

  List<TransactionData> get _filtered {
    switch (_filter) {
      case 1:
        return _allTx.where((t) => t.type == TxType.income).toList();
      case 2:
        return _allTx.where((t) => t.type == TxType.unknown).toList();
      default:
        return _allTx;
    }
  }

  @override
  Widget build(BuildContext context) {
    const chips = ['Все', 'Доход', 'Требует внимания'];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: Row(
                children: [
                  _BackButton(onTap: widget.onBack),
                  const SizedBox(width: 12),
                  Text(widget.month, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                children: [
                  const Row(
                    children: [
                      Expanded(child: _SummaryStat(label: 'Доход', value: '1 240 000 ₽', color: AppColors.accent)),
                      SizedBox(width: 10),
                      Expanded(child: _SummaryStat(label: 'Расход', value: '812 500 ₽', color: AppColors.warning)),
                      SizedBox(width: 10),
                      Expanded(child: _SummaryStat(label: 'Налог', value: '148 320 ₽', color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: chips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final active = i == _filter;
                        return GestureDetector(
                          onTap: () => setState(() => _filter = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: active ? AppColors.accentSoft : Colors.white,
                              border: Border.all(color: active ? AppColors.accent : AppColors.divider, width: 1.5),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(chips[i], style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: active ? AppColors.accent : AppColors.textSecondary)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(AppRadius.md + 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: _filtered.map((tx) => TransactionTile(tx: tx, showReviewBorder: true)).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color, fontFamily: 'JetBrainsMono')),
          ],
        ),
      );
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: AppColors.textPrimary),
        ),
      );
}
