import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../widgets/settings_section.dart';

/// "Настройки" tab — Account section (Profile / Tax Regime / Banks),
/// App section (Notifications / Export), and a destructive reset action.
class SettingsScreen extends StatelessWidget {
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenTaxRegime;
  final VoidCallback onOpenBanks;
  const SettingsScreen({
    super.key,
    required this.onOpenProfile,
    required this.onOpenTaxRegime,
    required this.onOpenBanks,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('Настройки', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ),
            SettingsSection(title: 'Аккаунт', rows: [
              SettingsRow(title: 'Профиль', onTap: onOpenProfile),
              SettingsRow(title: 'Налоговый режим', detail: 'ОСНО', onTap: onOpenTaxRegime),
              SettingsRow(title: 'Подключённые банки', detail: '2', onTap: onOpenBanks, isLast: true),
            ]),
            const SizedBox(height: 20),
            SettingsSection(title: 'Приложение', rows: [
              SettingsRow(
                title: 'Уведомления',
                trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppColors.accent),
              ),
              const SettingsRow(title: 'Экспорт данных (ФНС)', isLast: true),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.warningSoft,
                  side: const BorderSide(color: AppColors.warningBorder),
                  foregroundColor: AppColors.warning,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Сбросить данные', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
