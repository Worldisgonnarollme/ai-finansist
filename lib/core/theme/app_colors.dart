import 'package:flutter/material.dart';

import 'app_gradients.dart';

/// All raw color literals for AI-Финансист live here. No `Color(0xFF...)`
/// or `Colors.*` should appear anywhere else in the app.
///
/// Light theme: warm-white base, green as the single primary accent
/// (calculations, active states, positive amounts), warm orange reserved
/// for warnings/urgency only — never a primary action color.
///
/// Консолидация палитры (редизайн "под Настройки"): `background`,
/// `textPrimary`, `textSecondary`, `divider`, `accent`, `accentSoft` и
/// warning-семейство теперь РАВНЫ соответствующим `onb*`-токенам ниже —
/// раньше это были два независимых, но очень похожих набора (следы
/// поэтапного редизайна: Настройки/История/Выписки/Налоговый режим/
/// Онбординг сидели на `onb*`, всё остальное — на этих). Один источник
/// правды вместо двух почти одинаковых.
///
/// `accentDark`/`accentMid`/`accentLight` ОСТАВЛЕНЫ БЕЗ ИЗМЕНЕНИЙ намеренно
/// — это единственные потребители `AppGradients.primary` (карточка налога
/// на дашборде, шапка профиля, CTA онбординга) и одной надписи в
/// TaxSummaryCard._PeriodPill; трогать их — значит менять вид зелёной
/// карточки налога, чего явно просили не делать.
class AppColors {
  AppColors._();

  // Surfaces
  static const Color background = Color(
    0xFFFAF8F2,
  ); // screen background — same value as onbBg (see class doc)
  static const Color surface = Color(0xFFFFFFFF); // cards, sheets, bottom nav
  static const Color surfaceAlt = Color(
    0xFFF4EEE1,
  ); // chips, inputs, toggle track
  static const Color surfaceRail = Color(
    0xFFF6F3EA,
  ); // outer canvas / side rail bg

  // Accent — green is the ONLY primary accent. Brighter/more saturated than
  // the original muted forest green (was 0xFF2F6B4F) — same hue (~152°),
  // pushed to S≈50%/L≈34% for more visible fills (e.g. "Обновить данные").
  // Contrast vs white text/background stays ≈4.7:1 (WCAG AA).
  static const Color accent = Color(
    0xFF2B825A,
  ); // primary buttons, active state, tax amount — same value as onbGreen
  static const Color accentDark = Color(
    0xFF145C3A,
  ); // pressed state, gradient end (dark stop) — NOT consolidated, see class doc
  static const Color accentMid = Color(0xFF26925C); // gradient mid stop
  static const Color accentLight = Color(0xFF37A96E); // gradient light stop
  static const Color accentSoft = Color(
    0xFFE4EEE6,
  ); // icon/chip backgrounds on accent — same value as onbGreenSoft
  // Back-compat alias for the old dark-theme name — same role as accentSoft.
  static const Color accentSubtle = accentSoft;
  static const Color accentSecondary =
      accentLight; // back-compat alias, unused outside gradient

  // Warning / urgency — warm orange, NEVER used for primary actions
  static const Color warning = Color(0xFFE07A3F); // same value as onbOrange
  static const Color warningSoft = Color(
    0xFFF9E8DB,
  ); // banner fill — same value as onbOrangeSoft
  static const Color warningBorder = Color(0xFFF0CDAE); // banner border
  static const Color warningText = Color(
    0xFFB85C24,
  ); // banner copy (on warningSoft) — same value as onbOrangeText
  // Light apricot tint for expense bars in the monthly chart (softer than
  // full warning orange, per the design handoff's chart spec).
  static const Color warningLight = Color(0xFFF3BD91);

  // Semantic
  static const Color positive = accent; // income, gains
  static const Color negative =
      warning; // expense, risk (design uses warm orange, not red)

  // Text
  static const Color textPrimary = Color(0xFF1C2B23); // same value as onbInk
  static const Color textSecondary = Color(
    0xFF5C6B61,
  ); // same value as onbInkSoft
  static const Color textTertiary = Color(0xFF92988D);
  static const Color onAccent = Color(
    0xFFFFFFFF,
  ); // text/icons on solid green fills
  static const Color onGradient = Color(
    0xFFFFFFFF,
  ); // text on hero gradient (use opacity below)

  // Dividers / borders
  static const Color divider = Color(
    0xFFE6E2D6,
  ); // card borders — same value as onbLine
  static const Color dividerSoft = Color(0xFFF2EFE4); // list-row separators

  // deprecated: use AppGradients.primary — слияние градиентов, Этап 1
  // сборки дизайн-системы (prompt_design_cleanup.md). Раньше здесь был
  // отдельный трёхстоповый градиент, а AppGradients.primary — похожий,
  // но двухстоповый; теперь оба места указывают на один и тот же
  // трёхстоповый вариант.
  @Deprecated('use AppGradients.primary')
  static const LinearGradient heroGradient = AppGradients.primary;

  // Opacity ladder for text/fills ON the gradient hero card.
  static Color onGradientAlpha(double a) => onGradient.withValues(alpha: a);
  static const double onGradientPrimary = 0.95; // amount, headline
  static const double onGradientMuted = 0.75; // secondary copy
  static const double onGradientFaint = 0.7; // labels
  static const double fillOnGradient12 = 0.12; // payment-line pill fill
  static const double fillOnGradient18 = 0.18; // stronger fill
  static const double fillOnGradient22 = 0.22; // progress-track fill

  // Онбординг — светлая зелёно-оранжевая тема (flutter-onboarding-green-orange
  // skill), зафиксированная HTML-прототипами в docs/design/. После
  // консолидации палитры (см. класс-докстринг) значения ниже совпадают с
  // `background/textPrimary/textSecondary/accent/accentSoft/warning*` выше —
  // это теперь один и тот же цвет с двумя именами (основным и onb-алиасом),
  // а не два независимых тона.
  static const Color onbBg = Color(0xFFFAF8F2);
  static const Color onbInk = Color(0xFF1C2B23);
  static const Color onbInkSoft = Color(0xFF5C6B61);
  static const Color onbGreen = Color(0xFF2B825A); // same value as accent
  static const Color onbGreenDeep = Color(0xFF1E4A36);
  static const Color onbGreenSoft = Color(0xFFE4EEE6);
  static const Color onbOrange = Color(0xFFE07A3F);
  static const Color onbOrangeText = Color(0xFFB85C24);
  static const Color onbOrangeSoft = Color(0xFFF9E8DB);
  static const Color onbCard = Color(0xFFFFFFFF);
  static const Color onbLine = Color(0xFFE6E2D6);
  // Фон выбранной аккордеон-карточки (экран "Налоговый режим").
  static const Color onbSelectedTint = Color(0xFFF4F9F4);

  // Настройки (settings_page_prompt) — деструктивные действия внутри
  // онбординг-палитры. Никогда onbOrange для этого — только onbDanger.
  static const Color onbDanger = Color(0xFFB3402A);
  static const Color onbDangerSoft = Color(0xFFF7E4DE);
}
