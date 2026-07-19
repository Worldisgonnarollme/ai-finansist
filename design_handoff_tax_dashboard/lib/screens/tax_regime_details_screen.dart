import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../widgets/screen_header.dart';

/// ОСНО-specific settings: employee count stepper, VAT rate select,
/// VAT-exemption checkbox (ст. 145 НК РФ). Adapt the field set per regime
/// (e.g. УСН would show "объект налогообложения" instead of VAT rate).
class TaxRegimeDetailsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const TaxRegimeDetailsScreen({super.key, required this.onBack});

  @override
  State<TaxRegimeDetailsScreen> createState() => _TaxRegimeDetailsScreenState();
}

class _TaxRegimeDetailsScreenState extends State<TaxRegimeDetailsScreen> {
  int _employees = 3;
  String _vatRate = '20';
  bool _vatExempt = false;
  bool _saved = false;

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
            ScreenHeader(title: 'Настройки режима · ОСНО', onBack: widget.onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  const Text('СОТРУДНИКИ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.textTertiary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StepperButton(icon: Icons.remove, onTap: () => setState(() => _employees = (_employees - 1).clamp(0, 999))),
                        Text('$_employees', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'JetBrainsMono')),
                        _StepperButton(icon: Icons.add, onTap: () => setState(() => _employees++)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('СТАВКА НДС', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.textTertiary)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['20', '10', '0'].map((v) {
                      final active = _vatRate == v;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _vatRate = v),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: active ? AppColors.accentSoft : Colors.white,
                                border: Border.all(color: active ? AppColors.accent : AppColors.divider, width: 1.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('$v%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? AppColors.accent : AppColors.textPrimary)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => setState(() => _vatExempt = !_vatExempt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(color: AppColors.surfaceAlt.withOpacity(0.5), border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _vatExempt ? AppColors.accent : Colors.white,
                              border: Border.all(color: _vatExempt ? AppColors.accent : const Color(0xFFC9C0AC), width: 2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: _vatExempt ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(child: Text('Освобождение от НДС (ст. 145 НК РФ)', style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary))),
                        ],
                      ),
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
                  child: Text(_saved ? 'Сохранено ✓' : 'Сохранить', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: AppColors.surfaceAlt, border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: AppColors.textPrimary),
        ),
      );
}
