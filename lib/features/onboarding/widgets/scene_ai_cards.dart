import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import 'onb_chip.dart';
import 'scene_helpers.dart';

/// Карточки сцены шага 1 — советы ИИ. Desktop: 3 карточки (совет ИИ,
/// «Возврат клиенту ✓», чип риска НПД). Mobile: 2 (совет ИИ, чип риска) —
/// см. таблицу §4 скилла.
List<Widget> sceneAiCards({required double w, required double h, required bool isWide}) {
  Widget aiRow({required IconData icon, required Gradient iconGradient, String? label, required List<InlineSpan> spans}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isWide ? 38 : 32,
          height: isWide ? 38 : 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(gradient: iconGradient, borderRadius: BorderRadius.circular(AppRadius.sm - 1)),
          child: Icon(icon, size: isWide ? 18 : 15, color: AppColors.onbCard),
        ),
        SizedBox(width: isWide ? AppSpacing.sp12 : AppSpacing.sp8 + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null) ...[
                Text(label, style: AppTextStyles.onbCardLabel.copyWith(fontSize: isWide ? 11 : 10)),
                const SizedBox(height: 3),
              ],
              Text.rich(TextSpan(style: AppTextStyles.onbCardText.copyWith(fontSize: isWide ? 14 : 13), children: spans)),
            ],
          ),
        ),
      ],
    );
  }

  final adviceCard = FCard(
    isWide: isWide,
    child: aiRow(
      icon: Icons.auto_awesome_rounded,
      iconGradient: AppGradients.warm,
      label: 'СОВЕТ ОТ ИИ',
      spans: [
        const TextSpan(text: 'Уплатите страховые взносы до конца марта — налог уменьшится на '),
        TextSpan(
          text: '12 300 ₽.',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.onbGreenDeep),
        ),
      ],
    ),
  );

  final riskChip = FCard(
    isWide: isWide,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp12 + 2, vertical: AppSpacing.sp8 + 2),
    child: const OnbChip(label: 'Риск: доход близок к лимиту НПД', style: OnbChipStyle.orange),
  );

  if (!isWide) {
    return [
      scenePct(w, h, index: 0, left: 0.06, top: 0.24, width: 0.76, child: adviceCard),
      scenePct(w, h, index: 1, right: 0.08, bottom: 0.12, child: riskChip),
    ];
  }

  return [
    scenePct(w, h, index: 0, left: 0.09, top: 0.16, width: 0.62, child: adviceCard),
    scenePct(
      w,
      h,
      index: 1,
      right: 0.08,
      top: 0.50,
      width: 0.48,
      child: FCard(
        isWide: true,
        child: aiRow(
          icon: Icons.check_rounded,
          iconGradient: AppGradients.primary,
          spans: const [
            TextSpan(text: 'Операция «Возврат клиенту» не облагается налогом — исключили из базы.'),
          ],
        ),
      ),
    ),
    scenePct(w, h, index: 2, left: 0.14, bottom: 0.08, child: riskChip),
  ];
}
