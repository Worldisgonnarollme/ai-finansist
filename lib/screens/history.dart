import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../main.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final periods = state.periods;

    return Scaffold(
      appBar: AppBar(
        title: const Text('История'),
        centerTitle: false,
      ),
      body: periods.isEmpty
          ? const _Empty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: periods.length,
              separatorBuilder: (_, child) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final p = periods[i];
                return FadeSlideItem(
                  index: i,
                  child: _PeriodCard(
                    period: p,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/period',
                      arguments: {'year': p.year, 'month': p.month},
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded,
              size: 64, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'Нет данных',
            style: TextStyle(
                fontSize: 18,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Подключите банк или добавьте\nоперации вручную',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final dynamic period;
  final VoidCallback onTap;
  const _PeriodCard({required this.period, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      period.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: scheme.onSurface),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Stat(
                    label: 'Доход',
                    value: (period.income as num).rub,
                    color: scheme.secondary,
                  ),
                  const SizedBox(width: 24),
                  _Stat(
                    label: 'Налог',
                    value: (period.tax as num).rub,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 24),
                  _Stat(
                    label: 'Операций',
                    value: '${period.transactionCount}',
                    color: scheme.onSurfaceVariant,
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

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15, color: color)),
      ],
    );
  }
}
