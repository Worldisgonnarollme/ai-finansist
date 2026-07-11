import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../models/month_stat.dart';

class MonthlyChart extends StatefulWidget {
  final List<MonthStat> data;
  const MonthlyChart({super.key, required this.data});

  @override
  State<MonthlyChart> createState() => _MonthlyChartState();
}

class _MonthlyChartState extends State<MonthlyChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = widget.data.fold(0.0, (m, s) {
      final top = s.income > s.expense ? s.income : s.expense;
      return top > m ? top : m;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sp16),
          child: Row(
            children: [
              Text('Доходы и расходы', style: AppTextStyles.titleMedium),
              const Spacer(),
              const _Legend(color: AppColors.positive, label: 'Доход'),
              const SizedBox(width: AppSpacing.sp12),
              const _Legend(color: AppColors.warningLight, label: 'Расход'),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _anim,
          builder: (ctx, child) => SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxVal > 0 ? maxVal * 1.25 : 10000,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceAlt,
                    getTooltipItem: (group, gi, rod, ri) {
                      final stat = widget.data[group.x];
                      final isIncome = ri == 0;
                      final val = isIncome ? stat.income : stat.expense;
                      final label = isIncome ? 'Доход' : 'Расход';
                      final s = val
                          .toStringAsFixed(0)
                          .replaceAllMapped(
                            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                            (m) => '${m[1]} ',
                          );
                      return BarTooltipItem(
                        '$label\n$s ₽',
                        AppTextStyles.labelSmall.copyWith(
                          color: isIncome
                              ? AppColors.positive
                              : AppColors.negative,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= widget.data.length) {
                          return const SizedBox();
                        }
                        final m = widget.data[idx].month;
                        const abbr = [
                          'янв',
                          'фев',
                          'мар',
                          'апр',
                          'май',
                          'июн',
                          'июл',
                          'авг',
                          'сен',
                          'окт',
                          'ноя',
                          'дек',
                        ];
                        // Год показываем только на первом столбце и при
                        // переходе через границу года — без дублирования
                        final showYear =
                            idx == 0 ||
                            widget.data[idx - 1].month.year != m.year;
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sp8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                abbr[m.month - 1],
                                style: AppTextStyles.labelSmall.copyWith(
                                  letterSpacing: 0,
                                ),
                              ),
                              if (showYear)
                                Text(
                                  '${m.year}',
                                  style: AppTextStyles.overline,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal > 0 ? maxVal / 4 : 2500,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(widget.data.length, (i) {
                  final s = widget.data[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: s.income * _anim.value,
                        gradient: AppGradients.chart,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: s.expense * _anim.value,
                        color: AppColors.warningLight,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                    barsSpace: 4,
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppSpacing.sp4 + 1),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}
