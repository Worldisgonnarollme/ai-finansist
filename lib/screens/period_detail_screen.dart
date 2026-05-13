import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/transaction.dart';
import '../models/tax_mode.dart';
import '../main.dart';
import '../widgets/transaction_card.dart';

class PeriodDetailScreen extends StatefulWidget {
  final int year;
  final int month;
  const PeriodDetailScreen({super.key, required this.year, required this.month});

  @override
  State<PeriodDetailScreen> createState() => _PeriodDetailScreenState();
}

class _PeriodDetailScreenState extends State<PeriodDetailScreen> {
  String _filter = 'all'; // all | income | expense

  static const _months = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  String get _title =>
      '${_months[widget.month - 1]} ${widget.year}';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final all = state.txsForPeriod(widget.year, widget.month);
    final txs = _filtered(all);

    final income = all.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          _SummaryBar(income: income, taxMode: state.taxMode.shortName, scheme: Theme.of(context).colorScheme),
          _FilterBar(
            selected: _filter,
            onChanged: (v) => setState(() => _filter = v),
          ),
          Expanded(
            child: txs.isEmpty
                ? Center(
                    child: Text('Нет операций',
                        style: TextStyle(color: Colors.grey.shade400)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: txs.length,
                    separatorBuilder: (_, child) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => TransactionCard(tx: txs[i]),
                  ),
          ),
        ],
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

class _SummaryBar extends StatelessWidget {
  final double income;
  final String taxMode;
  final ColorScheme scheme;
  const _SummaryBar(
      {required this.income, required this.taxMode, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          _Item(label: 'Доход', value: income.rub, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 24),
          _Item(label: 'Режим', value: taxMode, color: scheme.primary),
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
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 16, color: color)),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _Chip(label: 'Все', value: 'all', selected: selected, onTap: onChanged),
          const SizedBox(width: 8),
          _Chip(label: 'Доходы', value: 'income', selected: selected, onTap: onChanged),
          const SizedBox(width: 8),
          _Chip(label: 'Расходы', value: 'expense', selected: selected, onTap: onChanged),
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
  const _Chip(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = value == selected;
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? scheme.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey.shade700,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
