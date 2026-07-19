import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

/// Карточка-группа настроек с заголовком. Desktop: заголовок внутри
/// карточки (padding 16 24 8). Mobile (compact): заголовок НАД карточкой
/// (см. §10 промпта — единственное структурное отличие, остальное общее).
class SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  final bool compact;

  const SettingsGroup({
    super.key,
    required this.title,
    required this.rows,
    this.compact = false,
  });

  List<BoxShadow> get _shadow => [
        BoxShadow(
          color: AppColors.onbGreenDeep.withValues(alpha: 0.16),
          blurRadius: compact ? 34 : 44,
          spreadRadius: compact ? -16 : -20,
          offset: Offset(0, compact ? 14 : 18),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.onbCard,
        borderRadius: BorderRadius.circular(AppRadius.lg - 4),
        boxShadow: _shadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sp24,
                AppSpacing.sp16,
                AppSpacing.sp24,
                AppSpacing.sp8,
              ),
              child: Text(title, style: AppTextStyles.settingsGroupTitle),
            )
          else
            const SizedBox(height: AppSpacing.sp4),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Container(height: 1, color: AppColors.onbLine),
            rows[i],
          ],
          if (!compact) const SizedBox(height: AppSpacing.sp4),
        ],
      ),
    );

    if (!compact) return card;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.sp4 + 2, 0, AppSpacing.sp4 + 2, AppSpacing.sp8),
          child: Text(title, style: AppTextStyles.settingsGroupTitle),
        ),
        card,
      ],
    );
  }
}
