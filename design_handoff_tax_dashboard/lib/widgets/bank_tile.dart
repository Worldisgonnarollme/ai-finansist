import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Connected/selectable bank row — colored initial badge + name + status
/// (Connected Banks screen shows status + "Отключить"; Bank Selection
/// screen shows a chevron instead).
class BankTile extends StatelessWidget {
  final String name;
  final Color color;
  final String initial;
  final String? statusText; // e.g. "Подключено 12.05.2026" — null on selection screen
  final VoidCallback? onTap;
  final VoidCallback? onDisconnect;
  final bool isLast;

  const BankTile({
    super.key,
    required this.name,
    required this.color,
    required this.initial,
    this.statusText,
    this.onTap,
    this.onDisconnect,
    this.isLast = false,
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
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
              child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  if (statusText != null) ...[
                    const SizedBox(height: 2),
                    Text(statusText!, style: const TextStyle(fontSize: 12, color: AppColors.accent)),
                  ],
                ],
              ),
            ),
            if (onDisconnect != null)
              TextButton(onPressed: onDisconnect, child: const Text('Отключить', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 12.5)))
            else if (onTap != null)
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
