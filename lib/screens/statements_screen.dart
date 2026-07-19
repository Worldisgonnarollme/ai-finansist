import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/bank_statement.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/ru_plural.dart';
import '../core/widgets/bordered_section_card.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/section_hero_card.dart';
import '../main.dart';

Future<void> _pickFile(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv', 'pdf'],
    withData: true,
  );
  if (result == null || result.files.first.bytes == null) return;
  final file = result.files.first;
  final ext = (file.extension ?? '').toLowerCase();
  if (!context.mounted) return;

  // Та же выписка (по имени файла) уже есть в списке — спрашиваем, точно
  // ли добавлять её ещё раз, а не молча дублируем.
  final alreadyAdded = context.read<AppState>().statements.any(
    (s) => s.fileName == file.name,
  );
  if (alreadyAdded) {
    final confirmed = await _confirmDuplicateImport(context);
    if (!confirmed || !context.mounted) return;
  }

  context.read<AppState>().importFile(
    file.bytes!.toList(),
    ext,
    fileName: file.name,
  );
}

// Небольшое всплывающее окно (AlertDialog), не на весь экран.
Future<bool> _confirmDuplicateImport(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.onbCard,
      title: Text('Выписка уже добавлена', style: AppTextStyles.titleMedium),
      content: Text(
        'Эта выписка уже учтена в расчётах и есть в списке. '
        'Вы точно хотите добавить выписку?',
        style: AppTextStyles.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Нет'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Да'),
        ),
      ],
    ),
  );
  return result ?? false;
}

// Небольшое всплывающее окно (AlertDialog), не на весь экран — удаляет
// выписку ВМЕСТЕ с её операциями (AppState.deleteStatement), поэтому
// подтверждение обязательно и явно предупреждает об этом.
Future<void> _confirmDelete(BuildContext context, BankStatement statement) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.onbCard,
      title: Text('Удалить выписку?', style: AppTextStyles.titleMedium),
      content: Text(
        '«${statement.fileName}» и ${statement.transactionCount} '
        'операций из неё будут удалены из расчёта. Это действие '
        'нельзя отменить.',
        style: AppTextStyles.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Отмена'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.onbDanger),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Удалить'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    context.read<AppState>().deleteStatement(statement.id);
  }
}

/// Загруженные банковские выписки (см. history_statements_prompt). Без
/// AppBar — заголовок обычным текстом в скролле, как на "Настройках".
/// Загрузить новую выписку можно из hero-карточки или из пустого состояния
/// — оба пути ведут в один и тот же AppState.importFile.
class StatementsScreen extends StatelessWidget {
  const StatementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final statements = state.statements;
    final isDesktop = MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
    final bottomPadding = isDesktop
        ? AppSpacing.sp32
        : MediaQuery.paddingOf(context).bottom + AppSpacing.sp16;

    return Scaffold(
      backgroundColor: AppColors.onbBg,
      body: SafeArea(
        bottom: false,
        // Паддинг — на всю ширину скролла, а не внутри ограниченной
        // maxWidth-колонки, иначе он "съедает" часть 1040 — см. §
        // settings.dart (тот же приём, тот же порог 1000).
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1000;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                compact ? AppSpacing.sp16 : AppSpacing.sp48,
                compact ? AppSpacing.sp16 + 2 : AppSpacing.sp32 + 4,
                compact ? AppSpacing.sp16 : AppSpacing.sp48,
                bottomPadding,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(compact: compact),
                      SizedBox(height: compact ? AppSpacing.sp16 - 2 : AppSpacing.sp24),
                      if (statements.isEmpty)
                        EmptyState(
                          icon: Icons.description_outlined,
                          title: 'Нет загруженных выписок',
                          subtitle: 'Загрузите CSV или PDF-выписку из банка,\nчтобы увидеть операции и налог',
                          action: FilledButton.icon(
                            onPressed: () => _pickFile(context),
                            icon: const Icon(Icons.upload_file_rounded),
                            label: const Text('Загрузить выписку'),
                          ),
                        )
                      else ...[
                        SectionHeroCard(
                          icon: Icons.folder_copy_outlined,
                          title: 'Выписки за всё время',
                          subtitle:
                              '${ruFiles(statements.length)} · '
                              '${ruOperations(statements.fold(0, (s, e) => s + e.transactionCount))}',
                          ctaLabel: 'Загрузить выписку',
                          ctaLoading: state.loading,
                          onCta: state.loading ? null : () => _pickFile(context),
                        ),
                        const SizedBox(height: AppSpacing.sp16),
                        BorderedSectionCard(
                          title: 'Файлы',
                          children: [
                            for (final statement in statements) _FileRow(statement: statement),
                          ],
                        ),
                      ],
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

// Раскладка — точная копия _Pagehead из settings.dart: Row (титул слева,
// подпись справа, общая базовая линия) на desktop, Column на mobile —
// чтобы заголовки экранов совпадали по положению и высоте шапки.
class _Header extends StatelessWidget {
  final bool compact;
  const _Header({required this.compact});

  @override
  Widget build(BuildContext context) {
    final title = Text('Выписки', style: AppTextStyles.historyH1);
    final sub = Text('Загруженные банковские выписки', style: AppTextStyles.historySub);

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

class _FileRow extends StatelessWidget {
  final BankStatement statement;
  const _FileRow({required this.statement});

  IconData get _icon =>
      statement.extension == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.table_chart_rounded;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM yyyy · HH:mm', 'ru_RU').format(statement.uploadedAt);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp16 + 2,
        vertical: AppSpacing.sp12 + 1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.onbGreenSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(_icon, size: 17, color: AppColors.onbGreen),
          ),
          const SizedBox(width: AppSpacing.sp12 + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: statement.fileName,
                  child: Text(
                    statement.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.historyRowTitle,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$date · ${ruOperations(statement.transactionCount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.historyRowSubtitle,
                ),
                const SizedBox(height: AppSpacing.sp4 + 2),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Доходы ${statement.income.rub}',
                      style: AppTextStyles.historyInlineAmount.copyWith(color: AppColors.onbGreen),
                    ),
                    Text(
                      'Расходы ${statement.expenses.rub}',
                      style: AppTextStyles.historyInlineAmount.copyWith(
                        color: AppColors.onbOrangeText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Спецификация нового дизайна предполагала здесь chevron
          // (переход на детали выписки), но такого экрана нет — сохраняем
          // существующее удаление, просто в новом визуальном языке.
          IconButton(
            onPressed: () => _confirmDelete(context, statement),
            icon: const Icon(Icons.delete_outline_rounded, size: 19),
            color: AppColors.onbInkSoft,
            tooltip: 'Удалить выписку',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(AppSpacing.sp8),
          ),
        ],
      ),
    );
  }
}
