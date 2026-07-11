import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/tax_mode.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/hover_cursor.dart';
import '../widgets/settings_section.dart';
import '../widgets/responsive_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            style: TextButton.styleFrom(foregroundColor: AppColors.negative),
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // См. комментарий в history.dart — тот же расчёт нижнего отступа под
    // плавающую пилюлю на мобильной ветке, статичный на десктопе.
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
    final bottomPadding = isDesktop
        ? AppSpacing.sp32
        : MediaQuery.paddingOf(context).bottom + AppSpacing.sp16;

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: SafeArea(
        bottom: false,
        child: ResponsivePage(
          maxWidth: 560,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.sp16,
              AppSpacing.sp8,
              AppSpacing.sp16,
              bottomPadding,
            ),
            children: [
              // Статичная сводка профиля — только отображение, без
              // редактирования. Читает те же поля AppState, что и
              // ProfileScreen, поэтому автоматически синхронизирована с
              // ним и с данными, подставленными при регистрации в
              // LoginScreen (см. AppState.setEmail/setPhoneNumber и т.д.
              // notifyListeners() перестраивает этот экран сразу же).
              _ProfileSummaryCard(state: state),
              const SizedBox(height: AppSpacing.sp16),
              SettingsSection(
                title: 'Аккаунт',
                children: [
                  SettingsRow(
                    child: _MenuRow(
                      icon: Icons.person_outline_rounded,
                      title: 'Изменить данные профиля',
                      value: state.userName.isNotEmpty
                          ? state.userName
                          : 'Не указано',
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                    ),
                  ),
                  SettingsRow(
                    child: _MenuRow(
                      icon: Icons.receipt_long_outlined,
                      title: 'Налоговый режим',
                      value: state.taxMode.shortName,
                      onTap: () => Navigator.pushNamed(context, '/tax-regime'),
                    ),
                  ),
                  SettingsRow(
                    child: _MenuRow(
                      icon: Icons.account_balance_outlined,
                      title: 'Подключённые банки',
                      value: state.connectedBanks.isEmpty
                          ? 'Не подключены'
                          : '${state.connectedBanks.length}',
                      onTap: () => Navigator.pushNamed(context, '/banks'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp32),
              OutlinedButton(
                onPressed: () => _clearData(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.negative,
                  side: const BorderSide(color: AppColors.negative),
                ),
                child: const Text('Сбросить данные'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Только для чтения: зеркало данных профиля (см. ProfileScreen) на
// экране "Настройки". Редактирование — по кнопке "Изменить данные
// профиля" ниже, которая ведёт на ProfileScreen.
class _ProfileSummaryCard extends StatelessWidget {
  final AppState state;
  const _ProfileSummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final contactParts = [
      if (state.email.isNotEmpty) state.email,
      if (state.phoneNumber.isNotEmpty) state.phoneNumber,
    ];
    final hasDetails =
        state.region.isNotEmpty ||
        state.activityType.isNotEmpty ||
        state.inn.isNotEmpty ||
        state.ogrnip.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SummaryAvatar(base64: state.avatarBase64),
              const SizedBox(width: AppSpacing.sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.userName.isNotEmpty
                          ? state.userName
                          : 'Пользователь',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contactParts.isEmpty
                          ? 'Данные не заполнены'
                          : contactParts.join(' · '),
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasDetails) ...[
            const SizedBox(height: AppSpacing.sp16),
            Container(height: 1, color: AppColors.dividerSoft),
            const SizedBox(height: AppSpacing.sp12),
            if (state.region.isNotEmpty)
              _InfoRow(label: 'Регион', value: state.region),
            if (state.activityType.isNotEmpty)
              _InfoRow(label: 'Вид деятельности', value: state.activityType),
            if (state.inn.isNotEmpty) _InfoRow(label: 'ИНН', value: state.inn),
            if (state.ogrnip.isNotEmpty)
              _InfoRow(label: 'ОГРНИП', value: state.ogrnip),
          ],
        ],
      ),
    );
  }
}

class _SummaryAvatar extends StatelessWidget {
  final String base64;
  const _SummaryAvatar({required this.base64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: AppColors.accentSoft,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: base64.isEmpty
          ? const Icon(Icons.person_rounded, size: 26, color: AppColors.accent)
          : Image.memory(base64Decode(base64), fit: BoxFit.cover),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sp8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.labelSmall)),
          const SizedBox(width: AppSpacing.sp12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HoverCursor(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sp12),
            Expanded(child: Text(title, style: AppTextStyles.titleMedium)),
            const SizedBox(width: AppSpacing.sp12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: AppSpacing.sp4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
