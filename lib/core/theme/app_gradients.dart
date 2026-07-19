import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Именованные градиенты. `primary` — единственный зелёный градиент
/// проекта (Этап 1 сборки дизайн-системы, `prompt_design_cleanup.md`):
/// раньше существовало два похожих градиента (`AppColors.heroGradient`,
/// 3 стопа, и этот `primary`, 2 стопа) — теперь оба места используют один
/// и тот же трёхстоповый вариант, `heroGradient` — deprecated-алиас сюда.
class AppGradients {
  AppGradients._();

  /// Hero-карта налога, шапка профиля, onboarding CTA/иллюстрация.
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentDark, AppColors.accentMid, AppColors.accentLight],
    stops: [0.0, 0.55, 1.0],
  );

  /// Бары и линии графиков: зелёный -> прозрачный вниз.
  static LinearGradient get chart => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.06)],
  );

  /// Тёплая бежевая заливка сгруппированных секций.
  static const beigeSection = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F2E7), Color(0xFFF1EAD9)],
  );

  /// Рыжий градиент — ТОЛЬКО бейдж расходов/предупреждений, никогда на
  /// кнопках и больших поверхностях.
  static const warm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0975F), Color(0xFFE0713A)],
  );

  // Онбординг (flutter-onboarding-green-orange skill) — орб, прогресс-бар
  // налога и линии степпера/индикатора, фон сцены.
  static const onbOrb = RadialGradient(
    center: Alignment(-0.36, -0.40),
    colors: [Color(0xFF7FB894), Color(0xFF3E7A5B), Color(0xFFE58B4E)],
    stops: [0.0, 0.42, 1.0],
  );

  static const onbProgress = LinearGradient(
    colors: [AppColors.onbGreen, AppColors.onbOrange],
  );

  static const onbSceneBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEDF3EC), Color(0xFFF3EEE2)],
  );

  /// Callout-карта настроек «Подключите банк» (120°).
  static const onbCallout = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment(1.2, 0.4),
    colors: [Color(0xFF2F6B4F), Color(0xFF1E4A36), Color(0xFF8A4A26)],
    stops: [0.0, 0.62, 1.0],
  );
}
