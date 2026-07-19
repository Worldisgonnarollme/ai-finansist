import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Same scale as the original dark app_text_styles.dart. UI copy stays on
/// Inter; monetary figures switch to JetBrains Mono (tabular figures) for
/// the "official ledger" feel requested for the redesign.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _interBase => GoogleFonts.inter(color: AppColors.textPrimary);
  static TextStyle get _monoBase => GoogleFonts.jetBrainsMono(color: AppColors.textPrimary);

  static TextStyle get displayLarge =>
      _interBase.copyWith(fontSize: 36, fontWeight: FontWeight.w700, height: 1.1);

  static TextStyle get headlineMedium =>
      _interBase.copyWith(fontSize: 22, fontWeight: FontWeight.w800);

  static TextStyle get titleMedium =>
      _interBase.copyWith(fontSize: 15, fontWeight: FontWeight.w600);

  static TextStyle get bodyMedium =>
      _interBase.copyWith(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary);

  static TextStyle get labelSmall => _interBase.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.textSecondary,
      );

  /// Hero tax amount — displayLarge + tabular figures, mono face.
  static TextStyle get amount =>
      _monoBase.copyWith(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -0.5);

  /// Amounts in lists / metric chips.
  static TextStyle get amountSmall =>
      _monoBase.copyWith(fontSize: 15, fontWeight: FontWeight.w700);
}
