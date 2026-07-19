import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Hero-карточка сводки на экранах "История"/"Выписки" — иконка, заголовок,
/// подпись и CTA-кнопка на всю ширину. Единый виджет, чтобы не дублировать
/// вёрстку между двумя экранами (см. history_statements_prompt).
class SectionHeroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback? onCta;
  final bool ctaLoading;

  const SectionHeroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onCta,
    this.ctaLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.onbGreenSoft, AppColors.onbOrangeSoft],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.onbGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 22, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.sp12 + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.historyHeroTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.historyHeroSubtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp16 - 2),
          SizedBox(
            width: double.infinity,
            child: _HeroCta(label: ctaLabel, onTap: onCta, loading: ctaLoading),
          ),
        ],
      ),
    );
  }
}

class _HeroCta extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  const _HeroCta({required this.label, required this.onTap, required this.loading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp12 + 2),
        decoration: BoxDecoration(
          color: AppColors.onbInk,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.onbCta.copyWith(fontSize: 14, color: Colors.white),
              ),
      ),
    );
  }
}
