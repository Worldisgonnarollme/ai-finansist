import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/bank.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/hover_cursor.dart';
import '../features/settings/widgets/settings_group.dart';
import '../widgets/responsive_page.dart';

/// Список подключённых банков — карточка-группа в духе экрана "Настройки"
/// (SettingsGroup: заголовок + строки с иконкой, разделённые линией).
class ConnectedBanksScreen extends StatelessWidget {
  const ConnectedBanksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final banks = state.connectedBanks;

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
              SettingsGroup(
                title: 'Банки',
                rows: [
                  if (banks.isEmpty)
                    const _EmptyRow()
                  else
                    for (final bank in banks)
                      _BankRow(
                        bank: bank,
                        onDisconnect: () => context
                            .read<AppState>()
                            .disconnectBank(bank.bankId),
                      ),
                  _AddBankRow(
                    onTap: () => Navigator.pushNamed(context, '/bank-select'),
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

// Иконка-чип 38×38 в акцентном цвете — тот же паттерн, что и у строк
// SettingsRow (features/settings/widgets/settings_row.dart), но с
// разной иконкой на строку (банк/добавить), поэтому строится локально,
// а не через сам SettingsRow (его onTap рассчитан на переход по всей
// строке, здесь же кликабельна только кнопка "Отключить").
class _RowIcon extends StatelessWidget {
  final IconData icon;
  const _RowIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, size: 17, color: AppColors.accent),
    );
  }
}

class _BankRow extends StatelessWidget {
  final ConnectedBank bank;
  final VoidCallback onDisconnect;
  const _BankRow({required this.bank, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp24,
        vertical: AppSpacing.sp12 + 2,
      ),
      child: Row(
        children: [
          _RowIcon(icon: Icons.account_balance_rounded),
          const SizedBox(width: AppSpacing.sp12 + 2),
          Expanded(
            child: Text(
              bank.bankName,
              style: AppTextStyles.settingsRowTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sp12),
          TextButton(
            onPressed: onDisconnect,
            style: TextButton.styleFrom(foregroundColor: AppColors.negative),
            child: const Text('Отключить'),
          ),
        ],
      ),
    );
  }
}

class _AddBankRow extends StatelessWidget {
  final VoidCallback onTap;
  const _AddBankRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HoverCursor(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp24,
            vertical: AppSpacing.sp12 + 2,
          ),
          child: Row(
            children: [
              const _RowIcon(icon: Icons.add_rounded),
              const SizedBox(width: AppSpacing.sp12 + 2),
              Text(
                'Добавить банк',
                style: AppTextStyles.settingsRowTitle.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp24,
        vertical: AppSpacing.sp12 + 2,
      ),
      child: Text(
        'Нет подключённых банков',
        style: AppTextStyles.settingsRowSubtitle,
      ),
    );
  }
}
