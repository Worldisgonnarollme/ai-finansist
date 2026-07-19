import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../widgets/screen_header.dart';

/// Add-transaction form: income/expense pill toggle, big centered amount
/// input (hero-style, borderless), category chips, date field, note.
class AddTransactionScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AddTransactionScreen({super.key, required this.onBack});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool _isIncome = false;
  String _category = 'Услуги';
  bool _saved = false;
  final _amountController = TextEditingController(text: '12 450');

  static const _categories = ['Услуги', 'Товары', 'Аренда', 'Прочее'];

  void _save() {
    setState(() => _saved = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) widget.onBack();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: 'Новая операция', onBack: widget.onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TypeChip(label: 'Доход', active: _isIncome, onTap: () => setState(() => _isIncome = true)),
                      const SizedBox(width: 8),
                      _TypeChip(label: 'Расход', active: !_isIncome, onTap: () => setState(() => _isIncome = false)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                    decoration: BoxDecoration(color: AppColors.background.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        const Text('СУММА', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.textTertiary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _amountController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFamily: 'JetBrainsMono'),
                          decoration: const InputDecoration(border: InputBorder.none),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('КАТЕГОРИЯ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.textTertiary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((c) {
                      final active = _category == c;
                      return GestureDetector(
                        onTap: () => setState(() => _category = c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                          decoration: BoxDecoration(
                            color: active ? AppColors.accentSoft : Colors.white,
                            border: Border.all(color: active ? AppColors.accent : AppColors.divider, width: 1.5),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(c, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? AppColors.accent : AppColors.textPrimary)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('ДАТА', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.textTertiary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
                    child: const Row(children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                      SizedBox(width: 10),
                      Text('9 июля 2026', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const Text('ОПИСАНИЕ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.textTertiary)),
                  const SizedBox(height: 8),
                  Container(
                    height: 70,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(12)),
                    child: const TextField(
                      maxLines: null,
                      decoration: InputDecoration(border: InputBorder.none, hintText: 'Комментарий к операции'),
                      style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_saved ? 'Сохранено ✓' : 'Сохранить операцию', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.accentSoft : Colors.white,
            border: Border.all(color: active ? AppColors.accent : AppColors.divider, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? AppColors.accent : AppColors.textPrimary)),
        ),
      );
}
