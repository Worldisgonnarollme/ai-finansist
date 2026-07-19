import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../widgets/segmented_toggle.dart';
import '../widgets/regime_option_tile.dart';

/// First-run status + regime picker. Status choice gates which regime
/// families are shown (НПД for self-employed; УСН/Патент/ОСНО for ИП).
/// Default preselected regime for ИП is ОСНО (per product decision).
class TaxModeScreen extends StatefulWidget {
  final VoidCallback onContinue;
  const TaxModeScreen({super.key, required this.onContinue});

  @override
  State<TaxModeScreen> createState() => _TaxModeScreenState();
}

class _TaxModeScreenState extends State<TaxModeScreen> {
  int _statusIndex = 1; // 0 = Самозанятый, 1 = ИП
  String _selectedRegime = 'osno';

  List<RegimeFamily> get _families {
    if (_statusIndex == 0) {
      return const [
        RegimeFamily(label: 'НПД', options: [
          RegimeOption(id: 'npd', name: 'Налог на профессиональный доход', desc: 'Для тех, кто работает без сотрудников', rate: '4% / 6%'),
        ]),
      ];
    }
    return const [
      RegimeFamily(label: 'УСН', options: [
        RegimeOption(id: 'usn6', name: 'Доходы', desc: 'Налог с общей суммы поступлений', rate: '6%'),
        RegimeOption(id: 'usn15', name: 'Доходы минус расходы', desc: 'Налог с разницы доходов и расходов', rate: '15%'),
      ]),
      RegimeFamily(label: 'Патент', options: [
        RegimeOption(id: 'patent', name: 'Патентная система', desc: 'Фиксированная стоимость патента', rate: 'фикс.'),
      ]),
      RegimeFamily(label: 'ОСНО', options: [
        RegimeOption(id: 'osno', name: 'Общая система', desc: 'НДФЛ 13–15% + НДС, полный бухучёт', rate: '13–15%'),
      ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Выберите статус', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  SizedBox(height: 6),
                  Text('Это определит доступные налоговые режимы', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: SegmentedToggle(
                options: const ['Самозанятый', 'ИП'],
                selectedIndex: _statusIndex,
                onChanged: (i) => setState(() {
                  _statusIndex = i;
                  _selectedRegime = i == 0 ? 'npd' : 'osno';
                }),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  for (final fam in _families) ...[
                    RegimeFamilyLabel(fam.label),
                    for (final opt in fam.options)
                      RegimeOptionTile(
                        option: opt,
                        selected: _selectedRegime == opt.id,
                        onTap: () => setState(() => _selectedRegime = opt.id),
                      ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Продолжить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
