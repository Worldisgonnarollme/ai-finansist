import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../widgets/screen_header.dart';
import '../widgets/regime_option_tile.dart';

/// Regime-change flow — same family/option list as TaxModeScreen, but
/// selecting an option immediately confirms and pops back.
class TaxRegimeSelectScreen extends StatefulWidget {
  final VoidCallback onBack;
  final String initialRegime;
  final bool isSelfEmployed;
  final ValueChanged<String> onSelected;
  const TaxRegimeSelectScreen({
    super.key,
    required this.onBack,
    required this.initialRegime,
    required this.isSelfEmployed,
    required this.onSelected,
  });

  @override
  State<TaxRegimeSelectScreen> createState() => _TaxRegimeSelectScreenState();
}

class _TaxRegimeSelectScreenState extends State<TaxRegimeSelectScreen> {
  late String _selected = widget.initialRegime;

  List<RegimeFamily> get _families {
    if (widget.isSelfEmployed) {
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
          children: [
            ScreenHeader(title: 'Смена режима', onBack: widget.onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  for (final fam in _families) ...[
                    RegimeFamilyLabel(fam.label),
                    for (final opt in fam.options)
                      RegimeOptionTile(
                        option: opt,
                        selected: _selected == opt.id,
                        onTap: () {
                          setState(() => _selected = opt.id);
                          widget.onSelected(opt.id);
                          widget.onBack();
                        },
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
