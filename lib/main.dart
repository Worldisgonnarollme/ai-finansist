import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_state.dart';
import 'services/storage_service.dart';
import 'models/bank.dart';
import 'models/tax_mode.dart';
import 'screens/onboarding.dart';
import 'screens/main_screen.dart';
import 'screens/tax_mode_screen.dart';
import 'screens/bank_selection_screen.dart';
import 'screens/bank_consent_screen.dart';
import 'screens/bank_loading_screen.dart';
import 'screens/period_detail_screen.dart';
import 'screens/add_transaction_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  final storage = await StorageService.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(storage),
      child: const AIFinancistApp(),
    ),
  );
}

// ── Colour palette (navy + orange) ───────────────────────────────────────────
const _kOrange = Color(0xFFFF9D3D);
const _kOrangeDeep = Color(0xFFE8820C);
const _kOrangeContainer = Color(0xFF2A1F0A);
const _kGreen = Color(0xFF34D399);
const _kGreenDark = Color(0xFF052A1A);
const _kGreenLight = Color(0xFF059669);
const _kGreenLightContainer = Color(0xFFD1FAE5);
const _kRed = Color(0xFFFC6E6E);
const _kRedLight = Color(0xFFE53E3E);
const _kBgDark = Color(0xFF0D1829);
const _kSurfaceDark = Color(0xFF162236);
const _kCardDark = Color(0xFF1D2D45);
const _kOutlineDark = Color(0xFF243250);
const _kOnSurfaceDark = Color(0xFFE8F0FF);
const _kOnSurfaceVariantDark = Color(0xFF6B7FA8);
const _kBgLight = Color(0xFFF0F4FA);

class AIFinancistApp extends StatelessWidget {
  const AIFinancistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AI Финансист',
        themeMode: state.isDark ? ThemeMode.dark : ThemeMode.light,
        theme: _lightTheme(),
        darkTheme: _darkTheme(),
        home: state.onboardingDone
            ? const MainScreen()
            : const OnboardingScreen(),
        routes: {
          '/main': (_) => const MainScreen(),
          '/tax-mode': (_) => const TaxModeScreen(),
          '/bank-select': (_) => const BankSelectionScreen(),
          '/add-tx': (_) => const AddTransactionScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/bank-consent') {
            final bank = settings.arguments as Bank;
            return MaterialPageRoute(
                builder: (_) => BankConsentScreen(bank: bank));
          }
          if (settings.name == '/bank-loading') {
            final bank = settings.arguments as Bank;
            return MaterialPageRoute(
                builder: (_) => BankLoadingScreen(bank: bank));
          }
          if (settings.name == '/period') {
            final args = settings.arguments as Map<String, int>;
            return MaterialPageRoute(
                builder: (_) => PeriodDetailScreen(
                    year: args['year']!, month: args['month']!));
          }
          return null;
        },
      ),
    );
  }

  ThemeData _darkTheme() {
    final cs = ColorScheme(
      brightness: Brightness.dark,
      primary: _kOrange,
      onPrimary: Colors.black,
      primaryContainer: _kOrangeContainer,
      onPrimaryContainer: const Color(0xFFFFD9A8),
      secondary: _kGreen,
      onSecondary: Colors.black,
      secondaryContainer: _kGreenDark,
      onSecondaryContainer: const Color(0xFFA7F3D0),
      tertiary: const Color(0xFF60A5FA),
      onTertiary: Colors.black,
      error: _kRed,
      onError: Colors.black,
      surface: _kSurfaceDark,
      onSurface: _kOnSurfaceDark,
      surfaceContainerHighest: _kCardDark,
      onSurfaceVariant: _kOnSurfaceVariantDark,
      outline: _kOutlineDark,
      outlineVariant: _kCardDark,
      scrim: Colors.black,
      inverseSurface: const Color(0xFFF5F7FA),
      onInverseSurface: _kBgDark,
      inversePrimary: _kOrangeDeep,
    );
    return _base(cs).copyWith(
      scaffoldBackgroundColor: _kBgDark,
      cardTheme: _cardTheme(_kCardDark),
      navigationBarTheme: _navBarTheme(
          _kSurfaceDark, _kOrangeContainer, _kOrange, _kOnSurfaceVariantDark),
      inputDecorationTheme: _inputTheme(_kCardDark, _kOutlineDark, _kOrange,
          _kOnSurfaceVariantDark),
    );
  }

  ThemeData _lightTheme() {
    final cs = ColorScheme(
      brightness: Brightness.light,
      primary: _kOrangeDeep,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFFEDD5),
      onPrimaryContainer: const Color(0xFF7C3500),
      secondary: _kGreenLight,
      onSecondary: Colors.white,
      secondaryContainer: _kGreenLightContainer,
      onSecondaryContainer: const Color(0xFF052E16),
      tertiary: const Color(0xFF2563EB),
      onTertiary: Colors.white,
      error: _kRedLight,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF0D1829),
      surfaceContainerHighest: const Color(0xFFEFF3FA),
      onSurfaceVariant: const Color(0xFF4A5A7A),
      outline: const Color(0xFFD1DCF0),
      outlineVariant: const Color(0xFFE8EFF8),
      scrim: Colors.black,
      inverseSurface: _kCardDark,
      onInverseSurface: _kOnSurfaceDark,
      inversePrimary: _kOrange,
    );
    return _base(cs).copyWith(
      scaffoldBackgroundColor: _kBgLight,
      cardTheme: _cardTheme(Colors.white),
      navigationBarTheme: _navBarTheme(Colors.white, const Color(0xFFFFEDD5),
          _kOrangeDeep, const Color(0xFF4A5A7A)),
      inputDecorationTheme: _inputTheme(Colors.white,
          const Color(0xFFD1DCF0), _kOrangeDeep, const Color(0xFF4A5A7A)),
    );
  }

  ThemeData _base(ColorScheme cs) => ThemeData(
        useMaterial3: true,
        colorScheme: cs,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: cs.onSurface,
          titleTextStyle: TextStyle(
            color: cs.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        dividerTheme:
            DividerThemeData(color: cs.outline, space: 1, thickness: 1),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: cs.primary),
        ),
      );

  CardThemeData _cardTheme(Color color) => CardThemeData(
        color: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      );

  NavigationBarThemeData _navBarTheme(Color bg, Color indicator,
      Color selected, Color unselected) =>
      NavigationBarThemeData(
        backgroundColor: bg,
        indicatorColor: indicator,
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final active = s.contains(WidgetState.selected);
          return TextStyle(
            color: active ? selected : unselected,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? selected : unselected)),
      );

  InputDecorationTheme _inputTheme(
      Color fill, Color border, Color focus, Color hint) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: focus, width: 2)),
        labelStyle: TextStyle(color: hint),
        hintStyle: TextStyle(color: hint),
      );
}

// ── Shared helpers ──────────────────────────────────────────────────────────

extension FormatNum on num {
  String get rub {
    final s = toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
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
        vsync: this, duration: const Duration(milliseconds: 420));
    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _opacity = Tween(begin: 0.0, end: 1.0).animate(curve);
    _slide = Tween(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(curve);
    Future.delayed(Duration(milliseconds: widget.index * 55),
        () { if (mounted) _ctrl.forward(); });
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
