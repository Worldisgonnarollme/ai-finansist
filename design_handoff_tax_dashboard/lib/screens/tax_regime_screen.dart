import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../widgets/screen_header.dart';

/// Current-regime overview: card with regime name + "Изменить" → select
/// flow, factual info cards (ОСНО specifics), "Внести изменения" →
/// details flow, and an optimization callout comparing to USN 15%.
class TaxRegimeScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onChangeRegime;
  final VoidCallback onEditDetails;
  const TaxRegimeScreen({super.key, required this.onBack, required this.onChangeRegime, required this.onEditDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: 'Налоговый режим', onBack: onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(AppRadius.md + 2)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('ТЕКУЩИЙ РЕЖИМ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.textSecondary)),
                              SizedBox(height: 6),
                              Text('ОСНО', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                              SizedBox(height: 2),
                              Text('Общая система налогообложения', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        TextButton(onPressed: onChangeRegime, child: const Text('Изменить', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _InfoLine(text: 'Ставка НДФЛ — 13% (15% с дохода свыше 5 млн ₽ в год)'),
                  const SizedBox(height: 8),
                  const _InfoLine(text: 'Ставка НДС — 20%, право на вычет входящего НДС сохраняется'),
                  const SizedBox(height: 8),
                  const _InfoLine(text: 'Сотрудников: 3 · требуется полный бухучёт'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onEditDetails,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.textPrimary, width: 1.5),
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Внести изменения', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('ОПТИМИЗАЦИЯ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.accent)),
                        SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
                            children: [
                              TextSpan(text: 'При переходе на УСН 15% («Доходы минус расходы») налог за квартал снизился бы до '),
                              TextSpan(text: '64 125 ₽', style: TextStyle(fontWeight: FontWeight.w700)),
                              TextSpan(text: ' — экономия '),
                              TextSpan(text: '84 195 ₽', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent)),
                              TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String text;
  const _InfoLine({required this.text});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Text(text, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary)),
      );
}
