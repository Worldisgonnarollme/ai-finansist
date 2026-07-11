import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/bank.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../widgets/responsive_page.dart';

class BankLoadingScreen extends StatefulWidget {
  final Bank bank;
  const BankLoadingScreen({super.key, required this.bank});

  @override
  State<BankLoadingScreen> createState() => _BankLoadingScreenState();
}

class _BankLoadingScreenState extends State<BankLoadingScreen> {
  int _stage = 0;
  bool _done = false;

  static const _stages = [
    'Подключаемся к банку…',
    'Загружаем операции…',
    'Анализируем транзакции…',
    'Рассчитываем налог…',
  ];

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    // Animate through stages while bank connection runs
    final connectionFuture = context.read<AppState>().connectBank(widget.bank);

    for (int i = 0; i < _stages.length - 1; i++) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _stage = i + 1);
    }

    await connectionFuture;

    if (mounted) {
      setState(() => _done = true);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.accent,
      body: SafeArea(
        child: ResponsivePage(
          maxWidth: 420,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _done
                      ? Container(
                          key: const ValueKey('done'),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.onAccent.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 56,
                            color: AppColors.onAccent,
                          ),
                        )
                      : SizedBox(
                          key: const ValueKey('loading'),
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            color: AppColors.onAccent,
                            strokeWidth: 3,
                          ),
                        ),
                ),
                const SizedBox(height: 48),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _done ? 'Готово!' : _stages[_stage],
                    key: ValueKey(_done ? 'done' : _stage),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.onAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!_done)
                  Text(
                    widget.bank.name,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.onAccent.withValues(alpha: 0.7),
                    ),
                  ),
                const SizedBox(height: 40),
                if (!_done) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: (_stage + 1) / _stages.length,
                      backgroundColor: AppColors.onAccent.withValues(
                        alpha: 0.2,
                      ),
                      color: AppColors.onAccent,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Шаг ${_stage + 1} из ${_stages.length}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onAccent.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
