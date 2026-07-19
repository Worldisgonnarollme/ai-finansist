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

  // ── Онбординг (flutter-onboarding-green-orange skill) ──────────────────
  // Собственная шкала размеров, зафиксированная HTML-прототипами в
  // docs/design/ — не совпадает с основной шкалой приложения, поэтому
  // именована отдельно, а не через .copyWith на существующих стилях.

  /// Заголовок h1: mobile 34, desktop через .copyWith(fontSize: 38–54).
  static TextStyle get onbHeadline => GoogleFonts.manrope(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.08,
    color: AppColors.onbInk,
  );

  /// Сумма hero-карты: mobile 24, desktop через .copyWith(fontSize: 30).
  static TextStyle get onbAmount => GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    color: AppColors.onbInk,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Описание шага: mobile 15, desktop через .copyWith(fontSize: 17).
  static TextStyle get onbDesc => GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppColors.onbInkSoft,
  );

  /// Текст внутри карточек сцены: mobile 13, desktop через .copyWith(14).
  static TextStyle get onbCardText => GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.onbInk,
  );

  /// UPPERCASE label карточек: mobile 10, desktop через .copyWith(11).
  static TextStyle get onbCardLabel => GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.onbInkSoft,
  );

  /// Текст внутри чипов.
  static TextStyle get onbChip =>
      GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600);

  /// CTA.
  static TextStyle get onbCta =>
      GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700);

  // ── Настройки (settings_page_prompt) ────────────────────────────────────
  // Собственная шкала — desktop-значение по умолчанию, mobile через
  // .copyWith(fontSize: ...) на вызывающей стороне (см. §10 промпта).

  /// Заголовок страницы: desktop 32, mobile 30.
  static TextStyle get settingsH1 => GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.onbInk,
  );

  /// Подзаголовок страницы: desktop 14, mobile 13.5.
  static TextStyle get settingsSub =>
      GoogleFonts.manrope(fontSize: 14, color: AppColors.onbInkSoft);

  /// Имя в hero: desktop 22, mobile 17.
  static TextStyle get settingsHeroName => GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    color: AppColors.onbInk,
  );

  /// E-mail в hero: desktop 14, mobile 12.5.
  static TextStyle get settingsHeroMail =>
      GoogleFonts.manrope(fontSize: 14, color: AppColors.onbInkSoft);

  /// UPPERCASE заголовок группы.
  static TextStyle get settingsGroupTitle => GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: AppColors.onbInkSoft,
  );

  /// Заголовок строки настройки: desktop 15, mobile 14.5.
  static TextStyle get settingsRowTitle => GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.onbInk,
  );

  /// Подзаголовок строки: desktop 12.5, mobile 12.
  static TextStyle get settingsRowSubtitle =>
      GoogleFonts.manrope(fontSize: 12.5, color: AppColors.onbInkSoft);

  /// Значение справа в строке.
  static TextStyle get settingsRowValue => GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.onbInkSoft,
  );

  /// Заголовок callout-карты: desktop 16, mobile 15.
  static TextStyle get settingsCalloutTitle => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.onbCard,
  );

  /// Текст callout-карты.
  static TextStyle get settingsCalloutBody => GoogleFonts.manrope(
    fontSize: 13.5,
    height: 1.45,
    color: AppColors.onbCard,
  );

  /// Заголовок danger-zone.
  static TextStyle get settingsDangerTitle => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.onbInk,
  );

  /// Описание danger-zone.
  static TextStyle get settingsDangerBody =>
      GoogleFonts.manrope(fontSize: 12.5, height: 1.4, color: AppColors.onbInkSoft);

  /// Текст кнопки danger-zone.
  static TextStyle get settingsDangerButton => GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.onbDanger,
  );

  // ── Налоговый режим (tax_regime_prompt) ─────────────────────────────────
  // Аккордеон выбора режима — экран tax_regime_prompt.md, эталоны
  // docs/design/tax_regime_{desktop,mobile}_v3.html. Шкала — desktop по
  // умолчанию, mobile через .copyWith(fontSize: ...) на вызывающей стороне.

  /// Заголовок экрана: desktop 32, mobile 22.
  static TextStyle get taxRegimeH1 => GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.onbInk,
  );

  /// Подзаголовок экрана: desktop 14, mobile 12.5.
  static TextStyle get taxRegimeSub =>
      GoogleFonts.manrope(fontSize: 14, color: AppColors.onbInkSoft);

  /// Название режима в шапке карточки: desktop 17, mobile 15.5.
  static TextStyle get taxRegimeCardName => GoogleFonts.manrope(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: AppColors.onbInk,
  );

  /// Чип ставки в шапке карточки: desktop 12, mobile 11.
  static TextStyle get taxRegimeChip =>
      GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700);

  /// Метка "для кого" в шапке карточки: desktop 12, mobile 10.5.
  static TextStyle get taxRegimeWho => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.onbInkSoft,
  );

  /// Описание внутри раскрытой карточки: desktop 14/height 1.55,
  /// mobile 12.5/height 1.5.
  static TextStyle get taxRegimeDesc => GoogleFonts.manrope(
    fontSize: 14,
    height: 1.55,
    color: AppColors.onbInkSoft,
  );

  /// Факт-пилюля: desktop 12, mobile 11.
  static TextStyle get taxRegimeFact => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.onbInkSoft,
  );

  /// Кнопка переключателя объекта УСН/АУСН: desktop 13, mobile 12.
  static TextStyle get taxRegimeObjectLabel =>
      GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700);

  /// Ссылка "Подробнее о режиме →": desktop 13, mobile 12.
  static TextStyle get taxRegimeMoreLink => GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.onbGreen,
  );

  /// "Выбрано: …" в нижней панели: desktop 13.5, mobile 12.
  static TextStyle get taxRegimePicked =>
      GoogleFonts.manrope(fontSize: 13.5, color: AppColors.onbInkSoft);

  /// Текст CTA нижней панели: desktop 15, mobile 16.
  static TextStyle get taxRegimeCta =>
      GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700);

  // ── История / Выписки (history_statements_prompt) ──────────────────────
  // Экраны под нижней навигацией, но на той же светлой onb-палитре, что и
  // настройки/налоговый режим — единая шкала без mobile/desktop-вариантов
  // (в отличие от онбординга, эти экраны не различают размер по брейкпоинту).

  /// Заголовок экрана.
  static TextStyle get historyH1 => GoogleFonts.manrope(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.onbInk,
  );

  /// Подзаголовок экрана.
  static TextStyle get historySub => GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.onbInkSoft,
  );

  /// Заголовок hero-карточки.
  static TextStyle get historyHeroTitle => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.onbInk,
  );

  /// Подпись hero-карточки.
  static TextStyle get historyHeroSubtitle => GoogleFonts.manrope(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.onbInkSoft,
  );

  /// Заголовок строки списка (месяц / имя файла).
  static TextStyle get historyRowTitle => GoogleFonts.manrope(
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    color: AppColors.onbInk,
  );

  /// Подпись строки списка (кол-во операций / дата).
  static TextStyle get historyRowSubtitle => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.onbInkSoft,
  );

  /// Значение в пилюле (сумма налога).
  static TextStyle get historyPillValue =>
      GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700);

  /// Инлайн-сумма доход/расход под именем файла (экран "Выписки").
  static TextStyle get historyInlineAmount =>
      GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700);
}

// Новый fontSize-литерал вне этого файла запрещён; сначала добавь
// именованный стиль сюда (Этап 2 сборки дизайн-системы,
// prompt_design_cleanup.md).
