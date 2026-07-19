import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import 'onb_chip.dart';
import 'scene_helpers.dart';

/// Карточки сцены шага 0 — расчёт налога. Desktop: 3 карточки (hero-налог,
/// отдельная карточка «Доход за квартал», glass-чип). Mobile: 2 (hero-налог,
/// объединённый чип «↗ +241 000 ₽ за квартал») — см. таблицу §4 скилла.
List<Widget> sceneTaxCards({required double w, required double h, required bool isWide}) {
  final hero = FCard(
    isWide: isWide,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isWide ? 'НАЛОГ К УПЛАТЕ · IV КВАРТАЛ' : 'НАЛОГ К УПЛАТЕ',
                    style: isWide
                        ? AppTextStyles.onbCardLabel.copyWith(fontSize: 11)
                        : AppTextStyles.onbCardLabel,
                  ),
                  SizedBox(height: isWide ? 6 : 4),
                  Text(
                    '41 200 ₽',
                    style: isWide
                        ? AppTextStyles.onbAmount.copyWith(fontSize: 30)
                        : AppTextStyles.onbAmount,
                  ),
                ],
              ),
            ),
            const OnbChip(label: 'УСН 6%'),
          ],
        ),
        SizedBox(height: isWide ? AppSpacing.sp16 : AppSpacing.sp12),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: Container(
            height: isWide ? 8 : 7,
            color: AppColors.onbGreenSoft,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.64,
              child: Container(decoration: const BoxDecoration(gradient: AppGradients.onbProgress)),
            ),
          ),
        ),
        SizedBox(height: isWide ? AppSpacing.sp8 : AppSpacing.sp8 - 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Уплачено 26 400 ₽',
              style: TextStyle(fontSize: isWide ? 12 : 11, color: AppColors.onbInkSoft),
            ),
            Text(
              isWide ? 'Срок: 28 апреля' : 'до 28 апр',
              style: TextStyle(fontSize: isWide ? 12 : 11, color: AppColors.onbInkSoft),
            ),
          ],
        ),
      ],
    ),
  );

  if (!isWide) {
    return [
      scenePct(w, h, index: 0, left: 0.06, top: 0.24, width: 0.70, child: hero),
      scenePct(
        w,
        h,
        index: 1,
        right: 0.06,
        bottom: 0.12,
        child: FCard(
          isWide: false,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp12 + 2, vertical: AppSpacing.sp8 + 2),
          child: const OnbChip(label: '↗ +241 000 ₽ за квартал', style: OnbChipStyle.orange),
        ),
      ),
    ];
  }

  return [
    scenePct(w, h, index: 0, left: 0.08, top: 0.14, width: 0.56, child: hero),
    scenePct(
      w,
      h,
      index: 1,
      right: 0.07,
      top: 0.52,
      width: 0.34,
      child: FCard(
        isWide: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const OnbChip(label: 'Доход за квартал', style: OnbChipStyle.orange, icon: Icons.trending_up_rounded),
            const SizedBox(height: AppSpacing.sp8),
            Text('+241 000 ₽', style: AppTextStyles.onbAmount.copyWith(fontSize: 24)),
          ],
        ),
      ),
    ),
    scenePct(
      w,
      h,
      index: 2,
      left: 0.12,
      bottom: 0.09,
      child: const OnbChip(label: 'Расчёт обновлён сегодня', style: OnbChipStyle.glass),
    ),
  ];
}
