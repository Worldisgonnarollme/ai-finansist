import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/widgets/settings_callout.dart';
import '../features/settings/widgets/settings_danger_zone.dart';
import '../features/settings/widgets/settings_group.dart';
import '../features/settings/widgets/settings_profile_hero.dart';
import '../features/settings/widgets/settings_row.dart';
import '../features/settings/widgets/settings_toggle.dart';
import '../models/tax_mode.dart';
import 'statements_screen.dart';

/// Настройки — точно по эталонам docs/design/settings_desktop_concept.html
/// (≥1000 по ширине контента) и settings_mobile_concept.html (<1000).
/// Брейкпоинт считается от констрейнтов ЭТОГО экрана (не всего окна) —
/// на широком десктопе main_screen.dart уже занял 260px под сайдбар,
/// поэтому здесь сравнивается именно оставшаяся ширина контента.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Локальные тумблеры — в приложении нет backend-хранилища для
  // уведомлений (аналогично декоративному колокольчику на дашборде),
  // поэтому состояние не персистится между запусками.
  bool _remindersOn = true;
  bool _digestOn = false;

  void _clearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Сбросить данные?', style: AppTextStyles.titleMedium),
        content: Text(
          'Все операции, подключённые банки и настройки будут удалены.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.onbDanger),
            onPressed: () {
              context.read<AppState>().clearData();
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }

  String _banksCountLabel(int n) {
    final mod100 = n % 100;
    final mod10 = n % 10;
    final word = (mod100 >= 11 && mod100 <= 14)
        ? 'банков'
        : switch (mod10) {
            1 => 'банк',
            2 || 3 || 4 => 'банка',
            _ => 'банков',
          };
    return '$n $word';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final banksConnected = state.connectedBanks.isNotEmpty;
    final statementsCount = state.statements.length;
    final totalTx = state.statements.fold<int>(0, (sum, s) => sum + s.transactionCount);

    return Scaffold(
      backgroundColor: AppColors.onbBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1000;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                compact ? AppSpacing.sp20 : AppSpacing.sp48,
                compact ? AppSpacing.sp16 + 2 : AppSpacing.sp32 + 4,
                compact ? AppSpacing.sp20 : AppSpacing.sp48,
                compact ? AppSpacing.sp32 + AppSpacing.sp48 : AppSpacing.sp48 + AppSpacing.sp16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Pagehead(compact: compact),
                      SizedBox(height: compact ? AppSpacing.sp16 - 2 : AppSpacing.sp24),
                      SettingsProfileHero(
                        avatarBase64: state.avatarBase64,
                        name: state.userName,
                        email: state.email,
                        taxModeLabel: state.taxMode.shortName,
                        banksConnected: banksConnected,
                        compact: compact,
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                      ),
                      SizedBox(height: compact ? AppSpacing.sp16 - 2 : AppSpacing.sp20),
                      if (!banksConnected) ...[
                        SettingsCallout(
                          compact: compact,
                          onTap: () => Navigator.pushNamed(context, '/bank-select'),
                        ),
                        SizedBox(height: compact ? AppSpacing.sp20 + 2 : AppSpacing.sp32 - 4),
                      ],
                      _GroupsLayout(
                        compact: compact,
                        accountGroup: SettingsGroup(
                          title: 'Аккаунт',
                          compact: compact,
                          rows: [
                            SettingsRow(
                              icon: Icons.person_outline_rounded,
                              title: 'Данные профиля',
                              subtitle: 'Имя, e-mail, пароль',
                              compact: compact,
                              trailing: compact
                                  ? const SettingsChevron()
                                  : SettingsValueTrailing(
                                      value: state.userName.isNotEmpty ? state.userName : 'Не указано',
                                    ),
                              onTap: () => Navigator.pushNamed(context, '/profile'),
                            ),
                            SettingsRow(
                              icon: Icons.receipt_long_outlined,
                              title: 'Налоговый режим',
                              subtitle: 'Влияет на формулу расчёта',
                              compact: compact,
                              trailing: SettingsChipTrailing(label: state.taxMode.shortName),
                              onTap: () => Navigator.pushNamed(context, '/tax-regime'),
                            ),
                            SettingsRow(
                              icon: Icons.account_balance_outlined,
                              iconOrange: true,
                              title: 'Подключённые банки',
                              subtitle: 'Автоимпорт операций',
                              compact: compact,
                              trailing: banksConnected
                                  ? SettingsChipTrailing(label: _banksCountLabel(state.connectedBanks.length))
                                  : SettingsChipTrailing(
                                      label: compact ? 'Нет' : 'Не подключены',
                                      orange: true,
                                    ),
                              onTap: () => Navigator.pushNamed(context, '/banks'),
                            ),
                          ],
                        ),
                        notificationsGroup: SettingsGroup(
                          title: 'Уведомления',
                          compact: compact,
                          rows: [
                            SettingsRow(
                              icon: Icons.alarm_rounded,
                              title: 'Напоминания о сроках уплаты',
                              subtitle: 'За 7 и за 1 день',
                              compact: compact,
                              trailing: SettingsToggle(value: _remindersOn),
                              onTap: () => setState(() => _remindersOn = !_remindersOn),
                            ),
                            SettingsRow(
                              icon: Icons.mail_outline_rounded,
                              title: 'Дайджест на почту',
                              subtitle: 'Итоги месяца и налог',
                              compact: compact,
                              trailing: SettingsToggle(value: _digestOn),
                              onTap: () => setState(() => _digestOn = !_digestOn),
                            ),
                          ],
                        ),
                        dataGroup: SettingsGroup(
                          title: 'Данные',
                          compact: compact,
                          rows: [
                            SettingsRow(
                              icon: Icons.download_rounded,
                              title: 'Экспорт операций',
                              subtitle: 'CSV или Excel',
                              compact: compact,
                              trailing: const SettingsChevron(),
                              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Экспорт скоро будет доступен'),
                                  backgroundColor: AppColors.surfaceAlt,
                                ),
                              ),
                            ),
                            SettingsRow(
                              icon: Icons.folder_outlined,
                              title: 'Загруженные выписки',
                              subtitle: statementsCount == 0
                                  ? 'Пока нет файлов'
                                  : '$statementsCount файла · $totalTx операций',
                              compact: compact,
                              trailing: const SettingsChevron(),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const StatementsScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: compact ? AppSpacing.sp16 - 2 : AppSpacing.sp20),
                      SettingsDangerZone(compact: compact, onTap: () => _clearData(context)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Pagehead extends StatelessWidget {
  final bool compact;
  const _Pagehead({required this.compact});

  @override
  Widget build(BuildContext context) {
    final title = Text('Настройки', style: compact ? AppTextStyles.settingsH1.copyWith(fontSize: 30) : AppTextStyles.settingsH1);
    final sub = Text(
      'Аккаунт, налоговый режим и данные',
      style: compact ? AppTextStyles.settingsSub.copyWith(fontSize: 13.5) : AppTextStyles.settingsSub,
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 4), sub],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [title, sub],
    );
  }
}

/// Сетка 2×2(+1) на desktop, одна колонка на mobile — «Данные» вторым
/// рядом слева на desktop (см. §3 промпта).
class _GroupsLayout extends StatelessWidget {
  final bool compact;
  final Widget accountGroup;
  final Widget notificationsGroup;
  final Widget dataGroup;

  const _GroupsLayout({
    required this.compact,
    required this.accountGroup,
    required this.notificationsGroup,
    required this.dataGroup,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        children: [
          accountGroup,
          const SizedBox(height: AppSpacing.sp20),
          notificationsGroup,
          const SizedBox(height: AppSpacing.sp20),
          dataGroup,
        ],
      );
    }
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: accountGroup),
            const SizedBox(width: AppSpacing.sp20),
            Expanded(child: notificationsGroup),
          ],
        ),
        const SizedBox(height: AppSpacing.sp20),
        Row(
          children: [
            Expanded(child: dataGroup),
            const SizedBox(width: AppSpacing.sp20),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }
}
