import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';

/// Один пункт плавающей навигации — пара иконок (обычная/активная), без
/// подписи (капсула показывает только иконки).
typedef FloatingNavItem = ({IconData icon, IconData activeIcon});

/// Плавающая капсула нижней навигации. Чистая отрисовка — currentIndex и
/// onTap принадлежат вызывающему коду (MainScreen), здесь никакой
/// навигационной логики нет. Единственное локальное состояние ниже —
/// hover на web/десктопе у отдельных табов (чисто визуальное, не влияет
/// на currentIndex/onTap).
class FloatingNavBar extends StatelessWidget {
  final List<FloatingNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  static const height = 64.0;
  static const _circleSize = 44.0;

  @override
  Widget build(BuildContext context) {
    final n = items.length;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Позиция круга считается от реальной измеренной ширины (а не
          // приближённо через Alignment), иначе центр круга съезжает
          // относительно центра таба — диаметр круга (44) слишком большая
          // доля ширины одного слота, чтобы этим пренебречь.
          final segmentWidth = constraints.maxWidth / n;
          final circleLeft =
              segmentWidth * currentIndex + (segmentWidth - _circleSize) / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                left: circleLeft,
                top: (height - _circleSize) / 2,
                child: Container(
                  width: _circleSize,
                  height: _circleSize,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < n; i++)
                    Expanded(
                      child: _NavTab(
                        icon: currentIndex == i
                            ? items[i].activeIcon
                            : items[i].icon,
                        active: currentIndex == i,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Один таб — тап-зона минимум 44×44, hand-курсор и лёгкая подсветка
/// (textSecondary → textPrimary) при наведении на web/десктопе. На
/// тач-устройствах MouseRegion просто не стреляет — платформенных
/// проверок не требуется.
class _NavTab extends StatefulWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _NavTab({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active
        ? AppColors.onAccent
        : (_hovered ? AppColors.textPrimary : AppColors.textSecondary);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Center(child: Icon(widget.icon, size: 22, color: color)),
        ),
      ),
    );
  }
}
