import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Bottom tab bar — 4 tabs, labels shown (per redesign brief: "всё видно
/// и структурировано" — unlike the old app which hid labels).
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  const AppBottomNavBar({super.key, required this.currentIndex, required this.onChanged});

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Главная'),
    (icon: Icons.history_rounded, activeIcon: Icons.history_rounded, label: 'История'),
    (icon: Icons.description_outlined, activeIcon: Icons.description_rounded, label: 'Выписки'),
    (icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Настройки'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 22),
      decoration: const BoxDecoration(
        color: Color(0xEBFFFFFF), // ~92% white, matches blurred glass look
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final active = i == currentIndex;
          final item = _items[i];
          final color = active ? AppColors.accent : AppColors.textTertiary;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(active ? item.activeIcon : item.icon, size: 21, color: color),
                  const SizedBox(height: 3),
                  Text(item.label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
