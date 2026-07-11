import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Общий пустой экран (история, выписки и т.д.) — раньше был приватным
/// `_Empty`, реализованным дважды с одинаковой версткой (Этап 4 сборки
/// дизайн-системы, prompt_design_cleanup.md). Дизайн — точная копия
/// прежнего `_Empty` из history.dart, а не эскиз из аудита (circle-иконка/
/// titleMedium/bodySmall), чтобы не менять внешний вид экранов.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp48 * 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.sp16),
          Text(title, style: AppTextStyles.screenTitle),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sp8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.sp24),
            action!,
          ],
        ],
      ),
    );
  }
}
