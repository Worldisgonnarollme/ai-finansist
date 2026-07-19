import 'package:flutter/material.dart';

/// Light theme palette for the tax-calculation app redesign.
/// White/beige base, green as the single primary accent (calculations,
/// active states, positive amounts), rust/orange reserved for warnings
/// and urgency. Replaces the old dark AppColors 1:1 — same token names,
/// new values — so existing widgets that reference AppColors.* keep working.
class AppColors {
  AppColors._();

  // Surfaces
  static const background = Color(0xFFEFECE3); // screen background (soft beige)
  static const surface = Color(0xFFFFFFFF); // cards, sheets, bottom nav
  static const surfaceAlt = Color(0xFFF1E9DA); // chips, inputs, toggle track
  static const surfaceRail = Color(0xFFEDEAE1); // outer canvas / side rail bg

  // Accent — green is the ONLY primary accent
  static const accent = Color(0xFF1F7A4F); // primary buttons, active state, tax amount
  static const accentDark = Color(0xFF145C3A); // pressed state, gradient end (dark stop)
  static const accentMid = Color(0xFF26925C); // gradient mid stop
  static const accentLight = Color(0xFF37A96E); // gradient light stop
  static const accentSoft = Color(0xFFE3F1E7); // icon/chip backgrounds on accent

  // Warning / urgency — rust-orange, NEVER used for primary actions
  static const warning = Color(0xFFC1591F);
  static const warningSoft = Color(0xFFFBEADB); // banner fill
  static const warningBorder = Color(0xFFEBCBA3); // banner border
  static const warningText = Color(0xFF8A3F14); // banner copy (on warningSoft)

  // Semantic
  static const positive = accent; // income, gains
  static const negative = warning; // expense, risk (design uses rust, not red)

  // Text
  static const textPrimary = Color(0xFF23261E);
  static const textSecondary = Color(0xFF78715F);
  static const textTertiary = Color(0xFF9C9484);
  static const onAccent = Color(0xFFFFFFFF); // text on green fills
  static const onGradient = Color(0xFFFFFFFF); // text on hero gradient (use opacity below)

  // Dividers / borders
  static const divider = Color(0xFFE7DFCE); // card borders
  static const dividerSoft = Color(0xFFF1EDE1); // list-row separators

  // Hero gradient (Dashboard variant 1) — 135deg, 3 stops
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentDark, accentMid, accentLight],
    stops: [0.0, 0.55, 1.0],
  );

  // Opacity ladder for text/fills ON the gradient hero card
  // (mirrors the old on-gradient/* semantic pattern, same alpha steps)
  static Color onGradientAlpha(double a) => onGradient.withOpacity(a);
  static const onGradientPrimary = 0.95; // amount, headline
  static const onGradientMuted = 0.75; // secondary copy
  static const onGradientFaint = 0.7; // labels
  static const fillOnGradient12 = 0.12; // payment-line pill fill
  static const fillOnGradient18 = 0.18; // stronger fill
  static const fillOnGradient22 = 0.22; // progress-track fill
}
