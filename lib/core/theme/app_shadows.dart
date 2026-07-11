import 'package:flutter/material.dart';

import 'app_colors.dart';

/// На светлой теме карточкам нужна тень или бордер, чтобы отделиться от
/// белого/светлого фона. Правило: `elevation` виджетов всегда 0; тень —
/// только через одну из трёх теней проекта — [card], [glow], [glowSoft] —
/// либо (для "тихих" карточек) бордер `AppColors.divider` без тени, но не
/// оба одновременно на одной карточке. Новый BoxShadow вне этого файла не
/// создавать (Этап 3 сборки дизайн-системы, prompt_design_cleanup.md).
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Зелёное свечение под крупными CTA на градиенте (onboarding, login).
  static List<BoxShadow> get glow => [
    BoxShadow(
      color: AppColors.accent.withValues(alpha: 0.25),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Лёгкое свечение для карточек с зелёным бордером/акцентом.
  static List<BoxShadow> get glowSoft => [
    BoxShadow(
      color: AppColors.accent.withValues(alpha: 0.10),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
