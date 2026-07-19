import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../widgets/screen_header.dart';
import '../widgets/bank_tile.dart';

class ConnectedBanksScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onAddBank;
  const ConnectedBanksScreen({super.key, required this.onBack, required this.onAddBank});

  static const _banks = [
    (name: 'Тинькофф Бизнес', color: Color(0xFFFFD500), initial: 'Т', status: 'Подключено 12.05.2026'),
    (name: 'Сбербанк', color: Color(0xFF21A038), initial: 'С', status: 'Подключено 03.02.2026'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: 'Подключённые банки', onBack: onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(14)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < _banks.length; i++)
                          BankTile(
                            name: _banks[i].name,
                            color: _banks[i].color,
                            initial: _banks[i].initial,
                            statusText: _banks[i].status,
                            onDisconnect: () {},
                            isLast: i == _banks.length - 1,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onAddBank,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.textTertiary, style: BorderStyle.solid, width: 1.5),
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('+ Добавить банк', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
