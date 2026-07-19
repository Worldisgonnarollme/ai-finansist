import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../data/onboarding_steps.dart';

/// Desktop-степпер 01/02/03 — кликабельные строки с номером, лейблом и
/// анимированной линией-прогрессом (§6 скилла). Замена точкам на mobile:
/// точки на desktop запрещены (§8), так же как степпер запрещён на mobile.
class OnboardingStepper extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;

  const OnboardingStepper({super.key, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < onboardingSteps.length; i++)
          _StepRow(
            index: i,
            label: onboardingSteps[i].navLabel,
            active: i == current,
            done: i < current,
            onTap: () => onTap(i),
          ),
      ],
    );
  }
}

class _StepRow extends StatefulWidget {
  final int index;
  final String label;
  final bool active;
  final bool done;
  final VoidCallback onTap;

  const _StepRow({
    required this.index,
    required this.label,
    required this.active,
    required this.done,
    required this.onTap,
  });

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final numBg = widget.active
        ? AppColors.onbGreen
        : widget.done
            ? AppColors.onbOrangeSoft
            : AppColors.onbGreenSoft;
    final numColor = widget.active
        ? AppColors.onbCard
        : widget.done
            ? AppColors.onbOrangeText
            : AppColors.onbInkSoft;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp12 + 2,
            vertical: AppSpacing.sp12,
          ),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.onbGreen.withValues(alpha: 0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md - 2),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: numBg, borderRadius: BorderRadius.circular(AppRadius.sm - 1)),
                child: Text('0${widget.index + 1}', style: AppTextStyles.captionBold.copyWith(color: numColor)),
              ),
              const SizedBox(width: AppSpacing.sp12 + 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: widget.active ? AppColors.onbInk : AppColors.onbInkSoft,
                ),
                child: Text(widget.label),
              ),
              const SizedBox(width: AppSpacing.sp8 + 2),
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(color: AppColors.onbLine, borderRadius: BorderRadius.circular(2)),
                  child: LayoutBuilder(
                    builder: (context, c) => AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      alignment: Alignment.centerLeft,
                      width: widget.active ? c.maxWidth : 0,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: AppGradients.onbProgress,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
