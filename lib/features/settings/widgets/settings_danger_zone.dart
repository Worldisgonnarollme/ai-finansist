import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

/// Отдельный блок деструктивного действия — пунктирная обводка, никакого
/// onbOrange (только onbDanger). Desktop: Row. Mobile (compact):
/// вертикально, кнопка full-width (см. §7/§10 промпта).
class SettingsDangerZone extends StatefulWidget {
  final VoidCallback onTap;
  final bool compact;

  const SettingsDangerZone({super.key, required this.onTap, this.compact = false});

  @override
  State<SettingsDangerZone> createState() => _SettingsDangerZoneState();
}

class _SettingsDangerZoneState extends State<SettingsDangerZone> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Сбросить данные', style: AppTextStyles.settingsDangerTitle),
        SizedBox(height: widget.compact ? 2 : 0),
        Text(
          'Удалит все операции, расчёты и подключения. Действие необратимо.',
          style: AppTextStyles.settingsDangerBody,
        ),
      ],
    );

    final button = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.compact ? double.infinity : null,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? AppSpacing.sp16 : AppSpacing.sp16 + 2,
            vertical: widget.compact ? AppSpacing.sp12 : AppSpacing.sp8 + 3,
          ),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.onbDangerSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.onbDangerSoft),
          ),
          child: Text('Сбросить…', style: AppTextStyles.settingsDangerButton),
        ),
      ),
    );

    return CustomPaint(
      painter: _DashedRRectPainter(
        color: AppColors.onbLine,
        radius: AppRadius.lg - 4,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? AppSpacing.sp16 : AppSpacing.sp24,
          vertical: widget.compact ? AppSpacing.sp16 : AppSpacing.sp16 + 2,
        ),
        child: widget.compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                text,
                const SizedBox(height: AppSpacing.sp12),
                button,
              ],
            )
          : Row(
              children: [
                Expanded(child: text),
                const SizedBox(width: AppSpacing.sp16 - 2),
                button,
              ],
            ),
      ),
    );
  }
}

/// Пунктирная рамка со скруглёнными углами — Flutter не умеет `dashed`
/// из коробки, а тащить пакет ради одной рамки избыточно.
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const gapWidth = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
