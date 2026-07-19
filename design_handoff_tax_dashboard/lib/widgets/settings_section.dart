import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// "SettingsSection" — uppercase section title + a card with rows
/// separated by 1px dividers. Used on Settings, Tax Regime, Connected Banks.
class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  const SettingsSection({super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.textTertiary)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(AppRadius.md + 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: rows),
        ),
      ],
    );
  }
}

/// One tappable row inside a SettingsSection: title + optional trailing
/// detail text + chevron. `isLast` removes the bottom divider.
class SettingsRow extends StatelessWidget {
  final String title;
  final String? detail;
  final VoidCallback? onTap;
  final bool isLast;
  final Widget? trailing; // e.g. a Switch, overrides detail+chevron

  const SettingsRow({
    super.key,
    required this.title,
    this.detail,
    this.onTap,
    this.isLast = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.dividerSoft)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
            if (trailing != null)
              trailing!
            else ...[
              if (detail != null) ...[
                Text(detail!, style: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary)),
                const SizedBox(width: 6),
              ],
              if (onTap != null) const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}
