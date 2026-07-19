import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../widgets/statement_card.dart';

/// "Выписки" tab — uploaded bank statements with a summary each.
/// Upload icon-button top-right → file picker (not modeled here).
class StatementsScreen extends StatelessWidget {
  final VoidCallback onUpload;
  const StatementsScreen({super.key, required this.onUpload});

  static const _statements = [
    (type: 'csv', name: 'Тинькофф_выписка_июнь.csv', date: '01.07.2026', count: 24, income: '1 240 000 ₽', expense: '812 500 ₽'),
    (type: 'pdf', name: 'Сбербанк_выписка_май.pdf', date: '02.06.2026', count: 19, income: '980 000 ₽', expense: '690 200 ₽'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Выписки', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                GestureDetector(
                  onTap: onUpload,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.upload_rounded, size: 18, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final s in _statements)
              StatementCard(fileType: s.type, fileName: s.name, date: s.date, count: s.count, income: s.income, expense: s.expense),
          ],
        ),
      ),
    );
  }
}
