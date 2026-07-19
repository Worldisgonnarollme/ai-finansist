import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'statements_screen.dart';
import 'settings_screen.dart';
import 'period_detail_screen.dart';
import 'profile_screen.dart';
import 'tax_regime_screen.dart';
import 'tax_regime_select_screen.dart';
import 'tax_regime_details_screen.dart';
import 'connected_banks_screen.dart';
import 'bank_selection_screen.dart';
import 'bank_consent_screen.dart';
import 'bank_loading_screen.dart';
import 'add_transaction_screen.dart';

/// Illustrative shell wiring the 4 tabs + push navigation for every
/// nested screen, using Flutter's Navigator. Replace with your project's
/// existing routing (named routes / go_router / etc.) — the point here is
/// just to show how the screens compose together.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const DashboardScreen(),
      HistoryScreen(onOpenPeriod: (month) => _push(PeriodDetailScreen(month: month, onBack: () => Navigator.pop(context)))),
      StatementsScreen(onUpload: () {}),
      SettingsScreen(
        onOpenProfile: () => _push(ProfileScreen(onBack: () => Navigator.pop(context))),
        onOpenTaxRegime: () => _push(TaxRegimeScreen(
          onBack: () => Navigator.pop(context),
          onChangeRegime: () => _push(TaxRegimeSelectScreen(
            onBack: () => Navigator.pop(context),
            initialRegime: 'osno',
            isSelfEmployed: false,
            onSelected: (_) {},
          )),
          onEditDetails: () => _push(TaxRegimeDetailsScreen(onBack: () => Navigator.pop(context))),
        )),
        onOpenBanks: () => _push(ConnectedBanksScreen(
          onBack: () => Navigator.pop(context),
          onAddBank: () => _push(BankSelectionScreen(
            onBack: () => Navigator.pop(context),
            onSelect: (name, color, initial) => _push(BankConsentScreen(
              onBack: () => Navigator.pop(context),
              bankName: name,
              bankColor: color,
              bankInitial: initial,
              onConfirm: () => _push(BankLoadingScreen(onDone: () => Navigator.of(context).popUntil((r) => r.isFirst))),
            )),
          )),
        )),
      ),
    ];

    return Scaffold(
      body: tabs[_tab],
      bottomNavigationBar: AppBottomNavBar(currentIndex: _tab, onChanged: (i) => setState(() => _tab = i)),
    );
  }
}
