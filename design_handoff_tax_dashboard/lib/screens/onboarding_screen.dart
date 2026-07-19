import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

class _OnbSlide {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OnbSlide(this.icon, this.title, this.subtitle);
}

const _slides = [
  _OnbSlide(Icons.calculate_outlined, 'Считайте налоги без ошибок',
      'Автоматический расчёт по вашим доходам и расходам — точно в срок.'),
  _OnbSlide(Icons.account_balance_outlined, 'Все операции — под контролем',
      'Подключите банк или загрузите выписку, а сумму к уплате мы посчитаем сами.'),
  _OnbSlide(Icons.trending_up_rounded, 'Оптимизируйте налоговую нагрузку',
      'Понятные подсказки помогут выбрать выгодный режим и не переплатить.'),
];

/// 3-slide onboarding with skip + dot pagination. On the last slide the
/// CTA reads "Начать" and navigates to TaxModeScreen; "Пропустить" does
/// the same immediately.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _index = 0;

  void _next() {
    if (_index < _slides.length - 1) {
      setState(() => _index++);
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_index];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onDone,
                child: const Text('Пропустить', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
                      child: Icon(slide.icon, size: 46, color: AppColors.accent),
                    ),
                    const SizedBox(height: 24),
                    Text(slide.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Text(slide.subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? AppColors.accent : AppColors.divider,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_index < _slides.length - 1 ? 'Далее' : 'Начать', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
