import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

/// Пилюля-CTA с оранжевой круглой стрелкой — full-width на mobile,
/// компактная на desktop (§5–6 скилла). Единственная разрешённая тень CTA —
/// см. .claude/skills/flutter-onboarding-green-orange, §2.
class OnboardingCta extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool fullWidth;

  const OnboardingCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.fullWidth = false,
  });

  @override
  State<OnboardingCta> createState() => _OnboardingCtaState();
}

class _OnboardingCtaState extends State<OnboardingCta> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = _pressed || _hovered ? AppColors.onbGreenDeep : AppColors.onbGreen;
    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.translationValues(0, _hovered && !_pressed ? -2 : 0, 0),
      width: widget.fullWidth ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: widget.fullWidth ? AppSpacing.sp16 : AppSpacing.sp32 + AppSpacing.sp4,
        vertical: widget.fullWidth ? AppSpacing.sp16 + 2 : AppSpacing.sp16 + 1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [
          BoxShadow(
            color: AppColors.onbGreenDeep.withValues(alpha: 0.5),
            blurRadius: 28,
            spreadRadius: -12,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: widget.fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
        mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Text(
            widget.label,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onbCard, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: AppSpacing.sp12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            transform: Matrix4.translationValues(_hovered && !_pressed ? 3 : 0, 0, 0),
            width: widget.fullWidth ? 24 : 26,
            height: widget.fullWidth ? 24 : 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.onbOrange, shape: BoxShape.circle),
            child: Icon(Icons.arrow_forward_rounded, size: widget.fullWidth ? 13 : 14, color: AppColors.onbCard),
          ),
        ],
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _pressed ? 0.98 : 1,
          child: button,
        ),
      ),
    );
  }
}
