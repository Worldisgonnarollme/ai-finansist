import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';
import '../models/tax_mode.dart';
import '../main.dart';

class TaxSummaryCard extends StatelessWidget {
  final AppState state;
  const TaxSummaryCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final d = state.displayMonth;
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
    ];
    final periodName = '${months[d.month - 1]} ${d.year}';
    final dueFmt = DateFormat('d MMMM', 'ru_RU').format(state.paymentDue);

    final gradStart =
        isDark ? const Color(0xFF1A0E00) : const Color(0xFFBF6200);
    final gradEnd =
        isDark ? const Color(0xFF2C1A00) : const Color(0xFFE8820C);
    final shadowColor = isDark
        ? const Color(0xFFFF9D3D).withValues(alpha: 0.30)
        : const Color(0xFFE8820C).withValues(alpha: 0.40);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradStart, gradEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Налог за $periodName',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          letterSpacing: 0.3),
                    ),
                    if (!state.isShowingCurrentMonth)
                      Text(
                        'Нет данных за текущий месяц',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15), width: 1),
                ),
                child: Text(
                  state.taxMode.shortName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Animated tax counter
          TweenAnimationBuilder<double>(
            key: ValueKey(state.currentTax),
            tween: Tween(begin: 0, end: state.currentTax),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (ctx, v, child) => Text(
              v.rub,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 20),
          Row(
            children: [
              _Detail(
                label: 'Доход',
                value: state.currentIncome.rub,
                icon: Icons.trending_up_rounded,
              ),
              const SizedBox(width: 28),
              _Detail(
                label: 'Оплатить до',
                value: dueFmt,
                icon: Icons.calendar_today_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Detail({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.white54),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
