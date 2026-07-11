import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/bank.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/hover_cursor.dart';
import '../widgets/settings_section.dart';
import '../widgets/responsive_page.dart';

class ConnectedBanksScreen extends StatelessWidget {
  const ConnectedBanksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Подключённые банки', style: AppTextStyles.headlineMedium),
      ),
      body: SafeArea(
        child: ResponsivePage(
          maxWidth: 560,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sp16,
              AppSpacing.sp8,
              AppSpacing.sp16,
              AppSpacing.sp32,
            ),
            children: [
              SettingsSection(
                title: 'Банки',
                children: [
                  if (state.connectedBanks.isEmpty)
                    SettingsRow(
                      child: Text(
                        'Нет подключённых банков',
                        style: AppTextStyles.bodyMedium,
                      ),
                    )
                  else
                    for (final bank in state.connectedBanks)
                      SettingsRow(
                        child: _BankRow(
                          bank: bank,
                          onDisconnect: () => context
                              .read<AppState>()
                              .disconnectBank(bank.bankId),
                        ),
                      ),
                  SettingsRow(
                    child: HoverCursor(
                      child: GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/bank-select'),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: AppSpacing.sp8),
                            Text(
                              'Добавить банк',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  final ConnectedBank bank;
  final VoidCallback onDisconnect;
  const _BankRow({required this.bank, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(bank.bankName, style: AppTextStyles.titleMedium)),
        TextButton(
          onPressed: onDisconnect,
          style: TextButton.styleFrom(foregroundColor: AppColors.negative),
          child: const Text('Отключить'),
        ),
      ],
    );
  }
}
