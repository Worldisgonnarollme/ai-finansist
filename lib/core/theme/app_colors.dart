import 'package:flutter/material.dart';

import 'app_gradients.dart';

/// All raw color literals for AI-Финансист live here. No `Color(0xFF...)`
/// or `Colors.*` should appear anywhere else in the app.
///
/// Light theme: warm-white base, green as the single primary accent
/// (calculations, active states, positive amounts), warm orange reserved
/// for warnings/urgency only — never a primary action color. Зелёная
/// семья (accent/accentDark/accentMid/accentLight/accentSoft) намеренно
/// оставлена без изменений при светлом редизайне (Этап 1) — менялись
/// только поверхности, текст и предупреждающий (рыжий) цвет.
class AppColors {
  AppColors._();

  // Surfaces
  static const Color background = Color(
    0xFFFDFCF9,
  ); // screen background (warm white, was beige)
  static const Color surface = Color(0xFFFFFFFF); // cards, sheets, bottom nav
  static const Color surfaceAlt = Color(
    0xFFF4EEE1,
  ); // chips, inputs, toggle track
  static const Color surfaceRail = Color(
    0xFFF6F3EA,
  ); // outer canvas / side rail bg

  // Accent — green is the ONLY primary accent (unchanged in Этап 1)
  static const Color accent = Color(
    0xFF1F7A4F,
  ); // primary buttons, active state, tax amount
  static const Color accentDark = Color(
    0xFF145C3A,
  ); // pressed state, gradient end (dark stop)
  static const Color accentMid = Color(0xFF26925C); // gradient mid stop
  static const Color accentLight = Color(0xFF37A96E); // gradient light stop
  static const Color accentSoft = Color(
    0xFFE3F1E7,
  ); // icon/chip backgrounds on accent
  // Back-compat alias for the old dark-theme name — same role as accentSoft.
  static const Color accentSubtle = accentSoft;
  static const Color accentSecondary =
      accentLight; // back-compat alias, unused outside gradient

  // Warning / urgency — warm orange, NEVER used for primary actions
  static const Color warning = Color(0xFFE8834A);
  static const Color warningSoft = Color(0xFFFBEEE3); // banner fill
  static const Color warningBorder = Color(0xFFF0CDAE); // banner border
  static const Color warningText = Color(
    0xFFA85A28,
  ); // banner copy (on warningSoft)
  // Light apricot tint for expense bars in the monthly chart (softer than
  // full warning orange, per the design handoff's chart spec).
  static const Color warningLight = Color(0xFFF3BD91);

  // Semantic
  static const Color positive = accent; // income, gains
  static const Color negative =
      warning; // expense, risk (design uses warm orange, not red)

  // Text
  static const Color textPrimary = Color(0xFF1B241F);
  static const Color textSecondary = Color(0xFF6E7A72);
  static const Color textTertiary = Color(0xFF92988D);
  static const Color onAccent = Color(
    0xFFFFFFFF,
  ); // text/icons on solid green fills
  static const Color onGradient = Color(
    0xFFFFFFFF,
  ); // text on hero gradient (use opacity below)

  // Dividers / borders
  static const Color divider = Color(0xFFEAE4D6); // card borders
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
}
