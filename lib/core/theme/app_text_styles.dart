import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Named text styles for AI-Финансист, built on Manrope for UI copy and
/// JetBrains Mono (tabular figures) for monetary amounts — the "official
/// ledger" feel of the light redesign.
///
/// Manrope ships only 400/500/700/800 weight cuts — there is no 600, so the
/// project standardises on those four everywhere (no `FontWeight.w600`
/// anywhere in the app): 400 body, 500 general titles/labels, 700 emphasis
/// (active state, standout values, buttons), 800 display/headline.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _uiBase =>
      GoogleFonts.manrope(color: AppColors.textPrimary);
  static TextStyle get _monoBase =>
      GoogleFonts.jetBrainsMono(color: AppColors.textPrimary);

  /// Onboarding hero headline. Kept at w700 (not the w800 the audit
  /// sketched) — the sole call site was already w700 and the sweep must
  /// not change appearance.
  static TextStyle get displayHero =>
      _uiBase.copyWith(fontSize: 42, fontWeight: FontWeight.w700, height: 1.1);

  static TextStyle get displayLarge =>
      _uiBase.copyWith(fontSize: 36, fontWeight: FontWeight.w700, height: 1.1);

  static TextStyle get headlineMedium =>
      _uiBase.copyWith(fontSize: 22, fontWeight: FontWeight.w800);

  /// Section headers (profile name, tax regime title).
  static TextStyle get titleXLarge =>
      _uiBase.copyWith(fontSize: 20, fontWeight: FontWeight.w800);

  /// AppBar / screen titles.
  static TextStyle get screenTitle =>
      _uiBase.copyWith(fontSize: 18, fontWeight: FontWeight.w800);

  static TextStyle get titleMedium =>
      _uiBase.copyWith(fontSize: 19, fontWeight: FontWeight.w500);

  static TextStyle get titleSmall =>
      _uiBase.copyWith(fontSize: 15, fontWeight: FontWeight.w500);

  static TextStyle get bodyMedium => _uiBase.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Most frequent body-copy size in the app (contact rows, hints, chips).
  static TextStyle get bodySmall => _uiBase.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle get caption => _uiBase.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle get captionBold =>
      _uiBase.copyWith(fontSize: 12, fontWeight: FontWeight.w700);

  static TextStyle get labelSmall => _uiBase.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: AppColors.textSecondary,
  );

  /// Smallest text in the project — chart axis labels, tiny badges.
  static TextStyle get overline => _uiBase.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );

  /// Tax figures, income totals — mono face, digits aligned in columns.
  static TextStyle get amount => _monoBase.copyWith(
    fontSize: 38,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  /// Smaller tabular amount, used in transaction tiles and chips.
  static TextStyle get amountSmall =>
      _monoBase.copyWith(fontSize: 17, fontWeight: FontWeight.w700);

  /// Smallest tabular amount — transaction rows, dashboard chips.
  static TextStyle get amountTiny =>
      _monoBase.copyWith(fontSize: 13, fontWeight: FontWeight.w700);
}

// Новый fontSize-литерал вне этого файла запрещён; сначала добавь
// именованный стиль сюда (Этап 2 сборки дизайн-системы,
// prompt_design_cleanup.md).
