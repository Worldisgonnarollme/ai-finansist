import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../widgets/screen_header.dart';
import '../widgets/bank_tile.dart';

class BankSelectionScreen extends StatelessWidget {
  final VoidCallback onBack;
  final void Function(String name, Color color, String initial) onSelect;
  const BankSelectionScreen({super.key, required this.onBack, required this.onSelect});

  static const _banks = [
    (name: 'Альфа-Банк', color: Color(0xFFEF3124), initial: 'А'),
    (name: 'ВТБ', color: Color(0xFF0A2896), initial: 'В'),
    (name: 'Точка', color: Color(0xFFFFDD2D), initial: 'Т'),
    (name: 'Модульбанк', color: Color(0xFF6C63FF), initial: 'М'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: 'Подключение банка', onBack: onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_user_outlined, size: 18, color: AppColors.accent),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Данные передаются по защищённому протоколу, доступ можно отозвать в любой момент.',
                            style: TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.accentDark),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                            onTap: () => onSelect(_banks[i].name, _banks[i].color, _banks[i].initial),
                            isLast: i == _banks.length - 1,
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
