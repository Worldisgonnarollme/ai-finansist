import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

/// Нижняя панель экрана "Налоговый режим" — "Выбрано: …" + CTA "Сохранить"
/// (§6 tax_regime_prompt.md). Desktop: строка, CTA справа; mobile: подпись
/// по центру над full-width CTA. Полупрозрачный фон + blur — как в
/// онбординге (см. onb_chip.dart), позиционирование (fixed/absolute)
/// решает вызывающий экран.
class RegimeBottomBar extends StatelessWidget {
  final String pickedLabel;
  final String ctaLabel;
  final bool enabled;
  final VoidCallback? onPressed;
  final bool compact;

  const RegimeBottomBar({
    super.key,
    required this.pickedLabel,
    required this.ctaLabel,
    required this.enabled,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.onbBg.withValues(alpha: 0.85),
            border: const Border(top: BorderSide(color: AppColors.onbLine)),
          ),
          padding: EdgeInsets.fromLTRB(
            compact ? AppSpacing.sp20 : AppSpacing.sp24,
            compact ? AppSpacing.sp12 + 2 : AppSpacing.sp16,
            compact ? AppSpacing.sp20 : AppSpacing.sp24,
            compact
                ? AppSpacing.sp16 + MediaQuery.paddingOf(context).bottom
                : AppSpacing.sp16,
          ),
          child: compact ? _MobileRow(this) : _DesktopRow(this),
        ),
      ),
    );
  }
}

class _DesktopRow extends StatelessWidget {
  final RegimeBottomBar bar;
  const _DesktopRow(this.bar);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            bar.pickedLabel,
            style: AppTextStyles.taxRegimePicked,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sp16),
        _Cta(bar: bar, fullWidth: false),
      ],
    );
  }
}

class _MobileRow extends StatelessWidget {
  final RegimeBottomBar bar;
  const _MobileRow(this.bar);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          bar.pickedLabel,
          textAlign: TextAlign.center,
          style: AppTextStyles.taxRegimePicked.copyWith(fontSize: 12),
        ),
        const SizedBox(height: AppSpacing.sp8 + 2),
        _Cta(bar: bar, fullWidth: true),
      ],
    );
  }
}

class _Cta extends StatelessWidget {
  final RegimeBottomBar bar;
  final bool fullWidth;
  const _Cta({required this.bar, required this.fullWidth});

  @override
  Widget build(BuildContext context) {
    final disabled = !bar.enabled;
    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.symmetric(
        horizontal: fullWidth ? AppSpacing.sp16 : AppSpacing.sp24 + 6,
        vertical: fullWidth ? AppSpacing.sp16 : AppSpacing.sp16 - 1,
      ),
      decoration: BoxDecoration(
        color: disabled ? AppColors.onbLine : AppColors.onbGreen,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: AppColors.onbGreenDeep.withValues(alpha: 0.5),
                  blurRadius: 28,
                  spreadRadius: -12,
                  offset: const Offset(0, 14),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            bar.ctaLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                (fullWidth
                        ? AppTextStyles.taxRegimeCta.copyWith(fontSize: 16)
                        : AppTextStyles.taxRegimeCta)
                    .copyWith(color: disabled ? AppColors.onbInkSoft : Colors.white),
          ),
          SizedBox(width: fullWidth ? AppSpacing.sp8 + 2 : AppSpacing.sp12),
          Container(
            width: fullWidth ? 22 : 24,
            height: fullWidth ? 22 : 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: disabled ? const Color(0xFFD8D4C8) : AppColors.onbOrange,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: 13,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    final tappable = GestureDetector(
      onTap: disabled ? null : bar.onPressed,
      behavior: HitTestBehavior.opaque,
      child: button,
    );

    return fullWidth ? SizedBox(width: double.infinity, child: tappable) : tappable;
  }
}
