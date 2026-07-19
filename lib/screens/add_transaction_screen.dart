import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/transaction.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../widgets/responsive_page.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _form = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  TransactionType _type = TransactionType.incomeIndividual;
  bool _saving = false;
  String? _amountError;

  static const _types = [
    (TransactionType.incomeIndividual, 'Доход от физлица'),
    (TransactionType.incomeLegal, 'Доход от юрлица/ИП'),
    (TransactionType.expense, 'Расход'),
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountText = _amountCtrl.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    setState(() {
      _amountError = amount == null || amount <= 0 ? 'Введите сумму' : null;
    });
    if (_amountError != null || !_form.currentState!.validate()) return;

    setState(() => _saving = true);
    final tx = Transaction(
      date: _date,
      amount: amount!,
      description: _descCtrl.text.trim(),
      type: _type,
      source: TransactionSource.manual,
    );
    await context.read<AppState>().addManual(tx);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ru'),
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Новая операция', style: AppTextStyles.headlineMedium),
      ),
      body: SafeArea(
        child: ResponsivePage(
          maxWidth: 560,
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sp16,
                AppSpacing.sp8,
                AppSpacing.sp16,
                AppSpacing.sp32,
              ),
              children: [
                _AmountField(
                  controller: _amountCtrl,
                  error: _amountError,
                  onChanged: (_) {
                    if (_amountError != null) {
                      setState(() => _amountError = null);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sp24),
                _SectionLabel('Тип операции'),
                const SizedBox(height: AppSpacing.sp8),
                _CategorySelector(
                  selected: _type,
                  onChanged: (t) => setState(() => _type = t),
                ),
                const SizedBox(height: AppSpacing.sp24),
                _SectionLabel('Дата'),
                const SizedBox(height: AppSpacing.sp8),
                _DateField(date: _date, onTap: _pickDate),
                const SizedBox(height: AppSpacing.sp24),
                _SectionLabel('Описание'),
                const SizedBox(height: AppSpacing.sp8),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Оплата услуг от Иванов А.П.',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Введите описание'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sp32),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : const Text('Сохранить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sp4),
      child: Text(text.toUpperCase(), style: AppTextStyles.labelSmall),
    );
  }
}

/// The amount is the hero of this screen — large, centered, tabular figures.
class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;
  const _AmountField({
    required this.controller,
    required this.error,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: controller,
            onChanged: onChanged,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.amount,
            decoration: InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: '0 ₽',
              hintStyle: AppTextStyles.amount.copyWith(
                color: AppColors.textSecondary,
              ),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.sp8),
            Text(
              error!,
              style: AppTextStyles.caption.copyWith(color: AppColors.negative),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;
  const _CategorySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _AddTransactionScreenState._types.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sp8),
        itemBuilder: (_, i) {
          final (type, label) = _AddTransactionScreenState._types[i];
          final active = type == selected;
          return GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: active ? null : Border.all(color: AppColors.divider),
              ),
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: active ? AppColors.onAccent : AppColors.textSecondary,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _DateField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp16,
          vertical: AppSpacing.sp16,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: AppColors.accent,
            ),
            const SizedBox(width: AppSpacing.sp12),
            Text(
              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
              style: AppTextStyles.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
