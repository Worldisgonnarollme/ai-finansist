import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/bank_statement.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/empty_state.dart';
import '../main.dart';
import '../widgets/responsive_page.dart';

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
      backgroundColor: AppColors.surface,
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

// Список загруженных выписок — вкладка нижней навигации наравне с
// Главной/Историей/Настройками. Загрузить новую выписку можно и отсюда
// (иконка в AppBar / кнопка в пустом состоянии), и одним нажатием с
// главного экрана — оба пути ведут в один и тот же AppState.importFile.
class StatementsScreen extends StatelessWidget {
  const StatementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final statements = state.statements;
    // См. комментарий в history.dart — тот же расчёт нижнего отступа под
    // плавающую пилюлю на мобильной ветке, статичный на десктопе.
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
    final bottomPadding = isDesktop
        ? AppSpacing.sp32
        : MediaQuery.paddingOf(context).bottom + AppSpacing.sp16;

    return Scaffold(
      appBar: AppBar(
        title: Text('Выписки', style: AppTextStyles.headlineMedium),
        actions: [
          IconButton(
            onPressed: state.loading ? null : () => _pickFile(context),
            icon: state.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  )
                : const Icon(Icons.upload_file_rounded),
            tooltip: 'Загрузить выписку',
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ResponsivePage(
          child: statements.isEmpty
              ? ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.sp16,
                    0,
                    AppSpacing.sp16,
                    bottomPadding,
                  ),
                  children: [
                    EmptyState(
                      icon: Icons.description_outlined,
                      title: 'Нет загруженных выписок',
                      subtitle:
                          'Загрузите CSV или PDF-выписку из банка,\nчтобы увидеть операции и налог',
                      action: FilledButton.icon(
                        onPressed: () => _pickFile(context),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Загрузить выписку'),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.sp16,
                    AppSpacing.sp8,
                    AppSpacing.sp16,
                    bottomPadding,
                  ),
                  itemCount: statements.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sp12),
                  itemBuilder: (_, i) =>
                      _StatementCard(statement: statements[i]),
                ),
        ),
      ),
    );
  }
}

// Небольшое всплывающее окно (AlertDialog), не на весь экран — удаляет
// выписку ВМЕСТЕ с её операциями (AppState.deleteStatement), поэтому
// подтверждение обязательно и явно предупреждает об этом.
Future<void> _confirmDelete(
  BuildContext context,
  BankStatement statement,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
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
          style: TextButton.styleFrom(foregroundColor: AppColors.negative),
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

class _StatementCard extends StatelessWidget {
  final BankStatement statement;
  const _StatementCard({required this.statement});

  IconData get _icon => statement.extension == 'pdf'
      ? Icons.picture_as_pdf_rounded
      : Icons.table_chart_rounded;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat(
      'd MMM yyyy · HH:mm',
      'ru_RU',
    ).format(statement.uploadedAt);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(_icon, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: AppSpacing.sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statement.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$date · ${statement.transactionCount} операций',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _confirmDelete(context, statement),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: AppColors.textSecondary,
                tooltip: 'Удалить выписку',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(AppSpacing.sp8),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp12),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sp12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Доходы',
                  value: statement.income.rub,
                  color: AppColors.positive,
                ),
              ),
              const SizedBox(width: AppSpacing.sp24),
              Expanded(
                child: _Metric(
                  label: 'Расходы',
                  value: statement.expenses.rub,
                  color: AppColors.negative,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
