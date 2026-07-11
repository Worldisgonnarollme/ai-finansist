import 'package:flutter/material.dart';
import '../models/bank.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../widgets/responsive_page.dart';

class BankConsentScreen extends StatelessWidget {
  final Bank bank;
  const BankConsentScreen({super.key, required this.bank});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          bank.name,
          style: AppTextStyles.screenTitle,
        ),
        centerTitle: true,
      ),
      body: ResponsivePage(
        maxWidth: 480,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sp24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: bank.color,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Center(
                    child: Text(
                      bank.name[0],
                      style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.onAccent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sp24),
              Text('Доступ к данным', style: AppTextStyles.headlineMedium),
              const SizedBox(height: AppSpacing.sp20),
              const _SectionLabel(
                label: 'Мы получим:',
                icon: Icons.check_circle_rounded,
                color: AppColors.accent,
              ),
              const SizedBox(height: AppSpacing.sp12),
              const _PermItem(text: 'Список операций по счёту'),
              const _PermItem(text: 'Суммы и даты платежей'),
              const _PermItem(text: 'Назначение платежей'),
              const SizedBox(height: AppSpacing.sp24),
              const _SectionLabel(
                label: 'Мы НЕ будем:',
                icon: Icons.cancel_rounded,
                color: AppColors.warning,
              ),
              const SizedBox(height: AppSpacing.sp12),
              const _PermItem(text: 'Совершать платежи', negative: true),
              const _PermItem(text: 'Видеть остаток на счёте', negative: true),
              const _PermItem(text: 'Хранить пароль от банка', negative: true),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sp16),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sp12),
                    Expanded(
                      child: Text(
                        'Вы можете отозвать доступ в любой момент в настройках.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sp20),
              FilledButton(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  '/bank-loading',
                  arguments: bank,
                ),
                child: const Text('Даю согласие'),
              ),
              const SizedBox(height: AppSpacing.sp12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionLabel({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.sp8),
        Text(
          label,
          style: AppTextStyles.titleSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PermItem extends StatelessWidget {
  final String text;
  final bool negative;
  const _PermItem({required this.text, this.negative = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sp8,
        bottom: AppSpacing.sp8 + 2,
      ),
      child: Row(
        children: [
          Icon(
            negative ? Icons.remove_circle_outline : Icons.check_rounded,
            size: 18,
            color: negative ? AppColors.warning : AppColors.accent,
          ),
          const SizedBox(width: AppSpacing.sp12),
          Text(
            text,
            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
