import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _PageData(
      icon: Icons.calculate_rounded,
      gradStart: Color(0xFF0D1829),
      gradEnd: Color(0xFF162236),
      accentColor: Color(0xFFFF9D3D),
      title: 'Считаем налог\nза вас',
      subtitle: 'Доходы из банков → готовый налог без\nручного ввода и таблиц',
    ),
    _PageData(
      icon: Icons.account_balance_rounded,
      gradStart: Color(0xFF091A12),
      gradEnd: Color(0xFF0D2B1C),
      accentColor: Color(0xFF34D399),
      title: 'Подключение\nбанков',
      subtitle: 'Импорт операций в один клик.\nАвтоматически каждый месяц.',
    ),
    _PageData(
      icon: Icons.auto_awesome_rounded,
      gradStart: Color(0xFF0D1829),
      gradEnd: Color(0xFF1D2D45),
      accentColor: Color(0xFFFF9D3D),
      title: 'Без\nбухгалтерии',
      subtitle: 'ИИ разберёт назначения платежей\nи отделит доходы от расходов.',
    ),
  ];

  void _next() {
    if (_page < 2) {
      _ctrl.nextPage(
          duration: const Duration(milliseconds: 380), curve: Curves.easeInOut);
    } else {
      _goToTaxMode();
    }
  }

  void _goToTaxMode() {
    context.read<AppState>().completeOnboarding();
    Navigator.pushReplacementNamed(context, '/tax-mode');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottom(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom() {
    final accent = _pages[_page].accentColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 52),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _page == i ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _page == i
                      ? accent
                      : Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _next,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            child: Text(_page == 2 ? 'Начать' : 'Далее'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _goToTaxMode,
            style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.6)),
            child: const Text('Пропустить'),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatefulWidget {
  final _PageData data;
  const _OnboardingPage({required this.data});

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2200),
        lowerBound: 0.92,
        upperBound: 1.0)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [d.gradStart, d.gradEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Pulsing icon ring
              ScaleTransition(
                scale: _pulse,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: d.accentColor.withValues(alpha: 0.12),
                    border: Border.all(
                        color: d.accentColor.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Icon(d.icon, size: 64, color: d.accentColor),
                ),
              ),
              const SizedBox(height: 44),
              Text(
                d.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                d.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 17,
                  height: 1.55,
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageData {
  final IconData icon;
  final Color gradStart;
  final Color gradEnd;
  final Color accentColor;
  final String title;
  final String subtitle;
  const _PageData({
    required this.icon,
    required this.gradStart,
    required this.gradEnd,
    required this.accentColor,
    required this.title,
    required this.subtitle,
  });
}
