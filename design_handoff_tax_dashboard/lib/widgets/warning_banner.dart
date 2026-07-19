import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Rust-colored alert banner used for two cases on the dashboard:
/// 1) NDFL scale-rate notice (static, not tappable)
/// 2) "unmarked transaction" nudge (tappable → opens period detail)
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16 - 2, vertical: 13),
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
              style: const TextStyle(color: AppColors.warningText, fontSize: 12.5, height: 1.4, fontFamily: 'Inter'),
            ),
          ),
          if (showChevron) Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.warningText),
        ],
      ),
    );
    return onTap != null ? GestureDetector(onTap: onTap, child: content) : content;
  }
}
