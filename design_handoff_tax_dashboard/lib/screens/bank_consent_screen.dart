import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../widgets/screen_header.dart';

/// Consent copy before connecting a bank. Confirm → BankLoadingScreen.
class BankConsentScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  final String bankName;
  final Color bankColor;
  final String bankInitial;

  const BankConsentScreen({
    super.key,
    required this.onBack,
    required this.onConfirm,
    required this.bankName,
    required this.bankColor,
    required this.bankInitial,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: bankName, onBack: onBack),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: bankColor, borderRadius: BorderRadius.circular(16)),
                      child: Text(bankInitial, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Согласие на получение данных', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    const Text(
                      'Приложение получит доступ к операциям по счетам ИП за последние 12 месяцев '
                      'для расчёта налога. Согласие действует 12 месяцев и может быть отозвано в любой момент.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Подтвердить и подключить', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
