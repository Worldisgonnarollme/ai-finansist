import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/bank.dart';
import 'onb_chip.dart';
import 'scene_helpers.dart';

/// Карточки сцены шага 2 — импорт из банков. Desktop: банки (3 строки) +
/// импортированные операции + glass-чип. Mobile: банки (2 строки) +
/// glass-чип, короче — см. таблицу §4 скилла.
List<Widget> sceneBanksCards({required double w, required double h, required bool isWide}) {
  Bank byId(String id) => kSupportedBanks.firstWhere((b) => b.id == id);
  final tinkoff = byId('tinkoff');
  final sber = byId('sberbank');
  final alfa = byId('alfa');

  Widget bankRow(Bank bank, {required bool connected, required bool isWide}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isWide ? AppSpacing.sp8 - 2 : AppSpacing.sp8 - 4),
      child: Row(
        children: [
          Container(
            width: isWide ? 34 : 28,
            height: isWide ? 34 : 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bank.color, borderRadius: BorderRadius.circular(AppRadius.sm - 1)),
            child: Text(
              bank.name.substring(0, 1),
              style: AppTextStyles.captionBold.copyWith(color: AppColors.onbInk, fontSize: isWide ? 13 : 12),
            ),
          ),
          SizedBox(width: isWide ? AppSpacing.sp12 : AppSpacing.sp8 + 2),
          Expanded(
            child: Text(
              bank.name,
              style: AppTextStyles.onbCardText.copyWith(fontWeight: FontWeight.w600, fontSize: isWide ? 14 : 13),
            ),
          ),
          if (connected)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.onbGreen)),
                const SizedBox(width: 4),
                Text('Подключён', style: TextStyle(fontSize: isWide ? 12 : 11, fontWeight: FontWeight.w600, color: AppColors.onbGreen)),
              ],
            )
          else
            Text('Подключить →', style: TextStyle(fontSize: isWide ? 12 : 11, color: AppColors.onbInkSoft)),
        ],
      ),
    );
  }

  final banksCard = FCard(
    isWide: isWide,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('ПОДКЛЮЧЁННЫЕ БАНКИ', style: AppTextStyles.onbCardLabel.copyWith(fontSize: isWide ? 11 : 10)),
        const SizedBox(height: AppSpacing.sp8 - 2),
        bankRow(tinkoff, connected: true, isWide: isWide),
        bankRow(sber, connected: true, isWide: isWide),
        if (isWide) bankRow(alfa, connected: false, isWide: isWide),
      ],
    ),
  );

  if (!isWide) {
    return [
      scenePct(w, h, index: 0, left: 0.06, top: 0.22, width: 0.64, child: banksCard),
      scenePct(
        w,
        h,
        index: 1,
        right: 0.06,
        bottom: 0.11,
        child: FCard(
          isWide: false,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp12 + 2, vertical: AppSpacing.sp8 + 2),
          child: const OnbChip(label: '132 операции — без ручного ввода', style: OnbChipStyle.glass),
        ),
      ),
    ];
  }

  return [
    scenePct(w, h, index: 0, left: 0.09, top: 0.13, width: 0.54, child: banksCard),
    scenePct(
      w,
      h,
      index: 1,
      right: 0.06,
      top: 0.46,
      width: 0.46,
      child: FCard(
        isWide: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ИМПОРТИРОВАНО СЕЙЧАС', style: AppTextStyles.onbCardLabel.copyWith(fontSize: 11)),
            const SizedBox(height: AppSpacing.sp8 - 2),
            _txRow('Оплата по договору №14', '+35 000 ₽', positive: true),
            _txRow('Оплата CRM', '−1 990 ₽', positive: false),
          ],
        ),
      ),
    ),
    scenePct(
      w,
      h,
      index: 2,
      left: 0.16,
      bottom: 0.08,
      child: const OnbChip(label: '132 операции за месяц — без ручного ввода', style: OnbChipStyle.glass),
    ),
  ];
}

Widget _txRow(String label, String amount, {required bool positive}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp4 + 2),
    child: Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.onbCardText.copyWith(fontWeight: FontWeight.w500))),
        Text(
          amount,
          style: AppTextStyles.amountTiny.copyWith(color: positive ? AppColors.onbGreen : AppColors.onbOrange),
        ),
      ],
    ),
  );
}
