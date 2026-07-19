import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Shared back-chevron pill used in every pushed screen's header
/// (Profile, Tax Regime, Connected Banks, Bank flow, Add Transaction, ...).
class BackButtonPill extends StatelessWidget {
  final VoidCallback onTap;
  const BackButtonPill({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: AppColors.textPrimary),
        ),
      );
}

/// Standard pushed-screen header: back pill + 18px/800 title, white bg,
/// bottom divider. Use inside a Column as the first child.
class ScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const ScreenHeader({super.key, required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
        child: Row(
          children: [
            BackButtonPill(onTap: onBack),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
          ],
        ),
      );
}
