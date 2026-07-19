import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/floating_nav_bar.dart';
import 'dashboard.dart';
import 'history.dart';
import 'statements_screen.dart';
import 'settings.dart';

typedef _NavItem = ({IconData icon, IconData activeIcon, String label});

const _navItems = <_NavItem>[
  (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Главная'),
  (
    icon: Icons.history_outlined,
    activeIcon: Icons.history_rounded,
    label: 'История',
  ),
  (
    icon: Icons.description_outlined,
    activeIcon: Icons.description_rounded,
    label: 'Выписки',
  ),
  (
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    label: 'Настройки',
  ),
];

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;

  static const _tabs = [
    DashboardScreen(),
    HistoryScreen(),
    StatementsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;

    if (isDesktop) {
      // Ноутбук/десктоп: постоянная боковая навигация вместо нижнего таб-бара
      // — на широком окне нижние табы читаются как мобильная страница,
      // а не веб-приложение (см. .interface-design/system.md).
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              selected: _idx,
              onSelected: (i) => setState(() => _idx = i),
            ),
            Expanded(
              child: IndexedStack(index: _idx, children: _tabs),
            ),
          ],
        ),
      );
    }

    // Клавиатура: пилюля не должна повиснуть над ней (актуально, если
    // когда-нибудь на одном из 4 табов появится инлайн-поле ввода — сейчас
    // их нет, ручной ввод — отдельный push-роут поверх этого Scaffold).
    //
    // Пилюля рисуется как Positioned-оверлей внутри Stack, а не через
    // Scaffold.bottomNavigationBar/extendBody — на этой комбинации Scaffold
    // на iOS-симуляторе кладёт bottomNavigationBar на середину экрана
    // (подтверждено измерением RenderBox: contentBottom считается сильно
    // меньше реальной высоты экрана), а не у нижнего края. Positioned с
    // bottom:-отступом всегда указывает на настоящий низ Stack независимо
    // от этого поведения Scaffold.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: IndexedStack(index: _idx, children: _tabs)),
          Positioned(
            left: AppSpacing.sp16,
            right: AppSpacing.sp16,
            bottom: math.max(AppSpacing.sp16, safeBottom),
            child: IgnorePointer(
              ignoring: keyboardOpen,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                opacity: keyboardOpen ? 0 : 1,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  offset: keyboardOpen ? const Offset(0, 1) : Offset.zero,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: FloatingNavBar(
                        items: [
                          for (final item in _navItems)
                            (icon: item.icon, activeIcon: item.activeIcon),
                        ],
                        currentIndex: _idx,
                        onTap: (i) => setState(() => _idx = i),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Боковая навигация для desktop-раскладки. Тот же фон, что и у канвы
// (background, не surface) — рейл не должен выглядеть отдельной "плашкой
// админки", а быть продолжением того же холста, с тонким разделителем
// справа (см. принцип "sidebars: same background as canvas").
class _Sidebar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;
  const _Sidebar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp16,
        vertical: AppSpacing.sp24,
      ),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.calculate_rounded,
                  size: 17,
                  color: AppColors.onAccent,
                ),
              ),
              const SizedBox(width: AppSpacing.sp8 + 2),
              Expanded(
                child: Text(
                  'AI-Финансист',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp32),
          for (int i = 0; i < _navItems.length; i++) ...[
            _SidebarItem(
              item: _navItems[i],
              active: selected == i,
              onTap: () => onSelected(i),
            ),
            if (i != _navItems.length - 1)
              const SizedBox(height: AppSpacing.sp4),
          ],
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  const _SidebarItem({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp12,
            vertical: AppSpacing.sp12 - 2,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Icon(
                active ? item.activeIcon : item.icon,
                size: 20,
                color: active ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sp12),
              Text(
                item.label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 14,
                  color: active ? AppColors.accent : AppColors.textPrimary,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
