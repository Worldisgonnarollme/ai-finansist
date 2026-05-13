import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/transaction.dart';

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
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final tx = Transaction(
      date: _date,
      amount: double.parse(_amountCtrl.text.replaceAll(',', '.')),
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
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ru'),
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить операцию',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _label('Тип операции'),
            const SizedBox(height: 8),
            ...List.generate(_types.length, (i) {
              final (type, label) = _types[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TypeTile(
                  label: label,
                  selected: _type == type,
                  onTap: () => setState(() => _type = type),
                ),
              );
            }),
            const SizedBox(height: 20),
            _label('Сумма (₽)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: '0',
                prefixText: '₽  ',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Введите сумму';
                if (double.tryParse(v.replaceAll(',', '.')) == null) {
                  return 'Некорректная сумма';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _label('Дата'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 18, color: scheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      '${_date.day.toString().padLeft(2, '0')}.${_date.month.toString().padLeft(2, '0')}.${_date.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _label('Описание'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Оплата услуг от Иванов А.П.',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Введите описание' : null,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      );
}

class _TypeTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeTile(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? scheme.primary : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? scheme.onPrimaryContainer : const Color(0xFF1A1C2E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
