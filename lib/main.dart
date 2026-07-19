import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'app_state.dart';
import 'core/theme/app_theme.dart';
import 'services/storage_service.dart';
import 'models/bank.dart';
import 'models/tax_mode.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'screens/bank_selection_screen.dart';
import 'screens/bank_consent_screen.dart';
import 'screens/bank_loading_screen.dart';
import 'screens/period_detail_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/tax_regime_screen.dart';
import 'features/tax_regime/tax_regime_screen.dart';
import 'screens/connected_banks_screen.dart';
import 'screens/bank_accounts_screen.dart';
import 'screens/account_operations_screen.dart';
import 'screens/login_screen.dart';
import 'models/bank_account.dart';

/// Позволяет показать SnackBar поверх экрана, на который мы уже
/// перешли (например, после Navigator.pop() из формы сохранения) —
/// без этого SnackBar пропадал бы вместе с закрываемым экраном.
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('ru_RU', null);
  final storage = await StorageService.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(storage),
      child: const AIFinancistApp(),
    ),
  );
}

class AIFinancistApp extends StatelessWidget {
  const AIFinancistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) => MaterialApp(
        scaffoldMessengerKey: rootMessengerKey,
        debugShowCheckedModeBanner: false,
        title: 'AI Financial agent',
        themeMode: ThemeMode.light,
        theme: AppTheme.theme,
        darkTheme: AppTheme.theme,
        // Без этого встроенные виджеты (DatePicker и т.п.) берут язык и
        // формат даты (MM/DD/YYYY, "Cancel"/"OK") из системной локали
        // устройства, а не из приложения — на английской системе выходит
        // англоязычный пикер поверх русского интерфейса.
        locale: const Locale('ru', 'RU'),
        supportedLocales: const [Locale('ru', 'RU')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // Системное увеличение шрифта пользователем не должно ломать
        // компактные элементы (пилюли сумм, чипы) — ограничиваем масштаб,
        // не отключая его совсем (см. history_statements_prompt).
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.2),
          ),
          child: child!,
        ),
        home: state.onboardingDone
            ? const MainScreen()
            : const OnboardingScreen(),
        routes: {
          '/main': (_) => const MainScreen(),
          // После регистрации/входа — тот же экран выбора режима, что и
          // "Изменить" на странице настроек (TaxRegimeScreen), просто в
          // режиме первичной настройки (см. isInitialSetup).
          '/tax-mode': (_) => const TaxRegimeSelectScreen(isInitialSetup: true),
          '/bank-select': (_) => const BankSelectionScreen(),
          '/add-tx': (_) => const AddTransactionScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/tax-regime': (_) => const TaxRegimeScreen(),
          '/banks': (_) => const ConnectedBanksScreen(),
          '/login': (_) => const LoginScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/bank-consent') {
            final bank = settings.arguments as Bank;
            return MaterialPageRoute(
              builder: (_) => BankConsentScreen(bank: bank),
            );
          }
          if (settings.name == '/bank-loading') {
            final bank = settings.arguments as Bank;
            return MaterialPageRoute(
              builder: (_) => BankLoadingScreen(bank: bank),
            );
          }
          if (settings.name == '/bank-accounts') {
            final bank = settings.arguments as ConnectedBank;
            return MaterialPageRoute(
              builder: (_) => BankAccountsScreen(bank: bank),
            );
          }
          if (settings.name == '/account-operations') {
            final account = settings.arguments as BankAccount;
            return MaterialPageRoute(
              builder: (_) => AccountOperationsScreen(account: account),
            );
          }
          if (settings.name == '/period') {
            final args = settings.arguments as Map<String, int>;
            return MaterialPageRoute(
              builder: (_) => PeriodDetailScreen(
                year: args['year']!,
                month: args['month']!,
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}

// ── Shared helpers ──────────────────────────────────────────────────────────

extension FormatNum on num {
  String get rub {
    final s = toStringAsFixed(
      0,
    ).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
    return '$s ₽';
  }
}

extension FormatTaxMode on TaxMode {
  String get label => displayName;
}

/// Entrance animation: fade + slide-up, staggered by [index].
class FadeSlideItem extends StatefulWidget {
  final int index;
  final Widget child;
  const FadeSlideItem({super.key, required this.index, required this.child});

  @override
  State<FadeSlideItem> createState() => _FadeSlideItemState();
}

class _FadeSlideItemState extends State<FadeSlideItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _opacity = Tween(begin: 0.0, end: 1.0).animate(curve);
    _slide = Tween(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(curve);
    Future.delayed(Duration(milliseconds: widget.index * 55), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}
