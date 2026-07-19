import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Пилюля-тумблер 44×26 — вкл/выкл onbLine/onbGreen, кружок 20×20 с тенью,
/// анимация 250мс easeOutCubic (см. settings_page_prompt, §6).
class SettingsToggle extends StatelessWidget {
  final bool value;

  const SettingsToggle({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? AppColors.onbGreen : AppColors.onbLine,
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.onbCard,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
        ),
      ),
    );
  }
}
