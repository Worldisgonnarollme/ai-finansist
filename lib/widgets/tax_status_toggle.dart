import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Переключатель статуса плательщика — две взаимоисключающие опции с явным
/// визуальным выделением активной (сегментированный контрол, а не радио-
/// кнопки/чекбоксы: выбор всегда ровно один из двух). Используется на
/// экране онбординга и в настройках, поэтому вынесен в общий виджет.
class TaxStatusToggle extends StatelessWidget {
  final bool isSelfEmployed;
  final ValueChanged<bool> onChanged;
  const TaxStatusToggle({
    super.key,
    required this.isSelfEmployed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatusOption(
              label: 'Самозанятый',
              active: isSelfEmployed,
              onTap: () => onChanged(true),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _StatusOption(
              label: 'Индивидуальный\nпредприниматель (ИП)',
              active: !isSelfEmployed,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _StatusOption({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp12),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.25,
            color: active ? AppColors.onAccent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
