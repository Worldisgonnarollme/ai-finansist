import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Rust-colored alert banner for tax-risk notices (income/VAT limits,
/// employee-count limits, unmarked transactions). Optionally tappable with
/// a trailing chevron — used when the banner should navigate somewhere
/// (e.g. the "unmarked transaction" nudge → period detail).
class WarningBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final bool showChevron;

  const WarningBanner({
    super.key,
    required this.icon,
    required this.text,
    this.onTap,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp16 - 2,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        border: Border.all(color: AppColors.warningBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.warningText,
                height: 1.4,
              ),
            ),
          ),
          if (showChevron)
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.warningText,
            ),
        ],
      ),
    );
    return onTap != null
        ? GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: content,
          )
        : content;
  }
}
