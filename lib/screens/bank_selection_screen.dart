import 'package:flutter/material.dart';
import '../models/bank.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/hover_cursor.dart';
import '../widgets/responsive_page.dart';

class BankSelectionScreen extends StatelessWidget {
  const BankSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Подключение банка', style: AppTextStyles.screenTitle),
        centerTitle: true,
      ),
      body: ResponsivePage(
        maxWidth: 560,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp16,
            vertical: AppSpacing.sp8,
          ),
          children: [
            const _SecurityBanner(),
            const SizedBox(height: AppSpacing.sp16),
            for (final bank in kSupportedBanks) ...[
              _BankTile(bank: bank),
              const SizedBox(height: AppSpacing.sp8 + 2),
            ],
          ],
        ),
      ),
    );
  }
}

class _SecurityBanner extends StatelessWidget {
  const _SecurityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp16,
        vertical: AppSpacing.sp12,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: AppSpacing.sp12),
          Expanded(
            child: Text(
              'Мы не храним логины и пароли. Только токен доступа только к выпискам.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accent,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BankTile extends StatelessWidget {
  final Bank bank;
  const _BankTile({required this.bank});

  @override
  Widget build(BuildContext context) {
    return HoverCursor(
      child: GestureDetector(
        onTap: () =>
            Navigator.pushNamed(context, '/bank-consent', arguments: bank),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sp16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md + 2),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bank.color,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    bank.name[0],
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sp16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            bank.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (bank.isRecommended) ...[
                          const SizedBox(width: AppSpacing.sp8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sp8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              'Рекомендуем',
                              style: AppTextStyles.labelSmall.copyWith(
                                letterSpacing: 0,
                                color: AppColors.onAccent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sp4),
                    Text('Подключить выписки', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
