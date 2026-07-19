import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

/// Callout «Подключите банк» — единственное незакрытое действие страницы.
/// Desktop: Row (иконка+текст+кнопка в одну линию). Mobile (compact):
/// текст сверху, кнопка full-width под ним (см. §10 промпта).
class SettingsCallout extends StatelessWidget {
  final VoidCallback onTap;
  final bool compact;

  const SettingsCallout({super.key, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: compact ? 38 : 44,
      height: compact ? 38 : 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.onbCard.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(compact ? AppRadius.sm - 1 : AppRadius.sm + 1),
      ),
      child: Icon(Icons.account_balance_rounded, size: compact ? 18 : 19, color: AppColors.onbCard),
    );

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Подключите банк',
          style: compact ? AppTextStyles.settingsCalloutTitle.copyWith(fontSize: 15) : AppTextStyles.settingsCalloutTitle,
        ),
        const SizedBox(height: 2),
        Text(
          'Операции будут импортироваться автоматически, а налог — считаться сам. '
          'Займёт две минуты.',
          style: AppTextStyles.settingsCalloutBody.copyWith(color: AppColors.onbCard.withValues(alpha: 0.85)),
        ),
      ],
    );

    final button = _CalloutButton(onTap: onTap, fullWidth: compact);

    return Container(
      padding: compact
          ? const EdgeInsets.all(AppSpacing.sp20)
          : const EdgeInsets.symmetric(horizontal: AppSpacing.sp24 + 2, vertical: AppSpacing.sp20 + 2),
      decoration: BoxDecoration(
        gradient: AppGradients.onbCallout,
        borderRadius: BorderRadius.circular(AppRadius.lg - 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.onbGreenDeep.withValues(alpha: 0.16),
            blurRadius: 44,
            spreadRadius: -20,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    icon,
                    const SizedBox(width: AppSpacing.sp12),
                    Expanded(child: text),
                  ],
                ),
                const SizedBox(height: AppSpacing.sp16 - 2),
                button,
              ],
            )
          : Row(
              children: [
                icon,
                const SizedBox(width: AppSpacing.sp16 + 2),
                Expanded(child: text),
                const SizedBox(width: AppSpacing.sp16 + 2),
                button,
              ],
            ),
    );
  }
}

class _CalloutButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool fullWidth;
  const _CalloutButton({required this.onTap, required this.fullWidth});

  @override
  State<_CalloutButton> createState() => _CalloutButtonState();
}

class _CalloutButtonState extends State<_CalloutButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.translationValues(0, _hovered && !widget.fullWidth ? -1 : 0, 0),
      width: widget.fullWidth ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: widget.fullWidth ? AppSpacing.sp16 : AppSpacing.sp16 + 6,
        vertical: widget.fullWidth ? AppSpacing.sp16 - 2 : AppSpacing.sp12 + 1,
      ),
      decoration: BoxDecoration(color: AppColors.onbCard, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Text('Подключить', style: AppTextStyles.onbCta.copyWith(fontSize: 14, color: AppColors.onbGreenDeep)),
          const SizedBox(width: AppSpacing.sp8 + 2),
          Container(
            width: widget.fullWidth ? 20 : 22,
            height: widget.fullWidth ? 20 : 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.onbOrange, shape: BoxShape.circle),
            child: Icon(Icons.arrow_forward_rounded, size: widget.fullWidth ? 10 : 11, color: AppColors.onbCard),
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
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _pressed && widget.fullWidth ? 0.98 : 1,
          child: content,
        ),
      ),
    );
  }
}
