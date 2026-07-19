import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../main.dart' show FadeSlideItem;

/// Позиционирует карточку сцены в процентах от фактического размера
/// сцены (не фиксированные px — иначе развалится на других диагоналях,
/// см. .claude/skills/flutter-onboarding-green-orange, §4/§8).
///
/// `Positioned` должен быть прямым ребёнком `Stack` — вход-анимация
/// (`FadeSlideItem`) оборачивает контент ВНУТРИ `Positioned`, а не
/// наоборот, иначе `Stack` игнорирует left/top/right/bottom и все
/// карточки схлопываются в один угол (тот же баг, что был в старой
/// screens/onboarding.dart).
Positioned scenePct(
  double w,
  double h, {
  required int index,
  double? left,
  double? top,
  double? right,
  double? bottom,
  double? width,
  required Widget child,
}) {
  return Positioned(
    left: left != null ? left * w : null,
    top: top != null ? top * h : null,
    right: right != null ? right * w : null,
    bottom: bottom != null ? bottom * h : null,
    width: width != null ? width * w : null,
    child: FadeSlideItem(index: index, child: child),
  );
}

/// Белая карточка сцены со скруглением 16 и единственной разрешённой
/// тенью карточек сцены (mobile/desktop радиус тени различается по §2).
class FCard extends StatelessWidget {
  final Widget child;
  final bool isWide;
  final EdgeInsetsGeometry? padding;

  const FCard({super.key, required this.child, required this.isWide, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: isWide ? AppSpacing.sp16 : AppSpacing.sp12 + 2,
            vertical: isWide ? AppSpacing.sp12 + 2 : AppSpacing.sp12 - 2,
          ),
      decoration: BoxDecoration(
        color: AppColors.onbCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.onbGreenDeep.withValues(alpha: isWide ? 0.22 : 0.24),
            blurRadius: isWide ? 60 : 44,
            spreadRadius: isWide ? -24 : -18,
            offset: Offset(0, isWide ? 24 : 18),
          ),
        ],
      ),
      child: child,
    );
  }
}
