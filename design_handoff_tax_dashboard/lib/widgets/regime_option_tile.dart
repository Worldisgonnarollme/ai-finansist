import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

class RegimeOption {
  final String id;
  final String name;
  final String desc;
  final String rate;
  const RegimeOption({required this.id, required this.name, required this.desc, required this.rate});
}

class RegimeFamily {
  final String label; // "УСН" | "Патент" | "ОСНО" | "НПД"
  final List<RegimeOption> options;
  const RegimeFamily({required this.label, required this.options});
}

/// One selectable regime row (radio-card) — used on Tax Mode screen and
/// the Tax Regime "change" flow. Selected = green border/fill/dot.
class RegimeOptionTile extends StatelessWidget {
  final RegimeOption option;
  final bool selected;
  final VoidCallback onTap;

  const RegimeOptionTile({super.key, required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sp8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface,
          border: Border.all(color: selected ? AppColors.accent : AppColors.divider, width: 1.5),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.accent : Colors.white,
                border: Border.all(color: selected ? AppColors.accent : const Color(0xFFC9C0AC), width: 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(option.desc, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(option.rate, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent, fontFamily: 'JetBrainsMono')),
          ],
        ),
      ),
    );
  }
}

/// Uppercase small section label above a family of regime options ("УСН").
class RegimeFamilyLabel extends StatelessWidget {
  final String text;
  const RegimeFamilyLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.textTertiary)),
      );
}
