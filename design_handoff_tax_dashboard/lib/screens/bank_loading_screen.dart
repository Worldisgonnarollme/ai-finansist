import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// 3-step connect animation: spinner → "Устанавливаем соединение…" →
/// "Загружаем операции…" → "Проверяем данные…" → green checkmark →
/// auto-dismiss back to Dashboard/ConnectedBanks.
class BankLoadingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const BankLoadingScreen({super.key, required this.onDone});

  @override
  State<BankLoadingScreen> createState() => _BankLoadingScreenState();
}

class _BankLoadingScreenState extends State<BankLoadingScreen> {
  int _step = 0;
  static const _labels = ['Устанавливаем соединение…', 'Загружаем операции…', 'Проверяем данные…', 'Готово! Банк подключён.'];

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_step < 3) {
        setState(() => _step++);
        if (_step < 3) {
          _tick();
        } else {
          Future.delayed(const Duration(milliseconds: 1200), widget.onDone);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = _step >= 3;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!done)
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.accent, backgroundColor: AppColors.accentSoft),
              )
            else
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
              ),
            const SizedBox(height: 20),
            Text(_labels[_step], style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
