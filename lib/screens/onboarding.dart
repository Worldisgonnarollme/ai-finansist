// lib/screens/onboarding.dart
//
// Визуальный редизайн: Clean Mint
// Структура классов и вся бизнес-логика (_next, _goToTaxMode, PageController)
// сохранены без изменений — заменён только визуальный слой.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

// ─── Модель данных слайда ────────────────────────────────────────────────────

class _PageData {
  const _PageData({
    required this.icon,
    required this.tag,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String tag;
  final String title;
  final String subtitle;
}

// ─── Публичная точка входа ───────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

// ─── Состояние: PageController, навигация ────────────────────────────────────

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    _PageData(
      icon: Icons.calculate_rounded,
      tag: 'Автоматический расчёт',
      title: 'Считаем налог\nза вас',
      subtitle:
          'Загружаем выписку из банка и сами вычисляем налог по вашей системе — УСН, НПД, ОСНО и другим.',
    ),
    _PageData(
      icon: Icons.account_balance_rounded,
      tag: 'Подключение банков',
      title: 'Автоимпорт\nопераций',
      subtitle:
          'Подключите Сбер, Тинькофф, Альфа или любой другой банк — операции поступают автоматически.',
    ),
    _PageData(
      icon: Icons.auto_awesome_rounded,
      tag: 'Искусственный интеллект',
      title: 'Без\nбухгалтерии',
      subtitle:
          'ИИ классифицирует каждую операцию, даёт советы по оптимизации и предупреждает о рисках.',
    ),
  ];

  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Бизнес-логика (не трогать) ────────────────────────────────────────────

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } else {
      _goToTaxMode();
    }
  }

  void _goToTaxMode() {
    context.read<AppState>().completeOnboarding();
    // После онбординга — форма входа/регистрации, затем выбор налогового
    // режима (см. LoginScreen._submit/_signInAnonymously).
    Navigator.pushReplacementNamed(context, '/login');
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // На десктопе/веб онбординг — полноэкранный сплит-скрин
            // (иллюстрация + текст в одном ряду на всю ширину окна), а не
            // узкая карточка по центру: см. пожелание "на ВЕСЬ экран".
            final isWide = constraints.maxWidth >= AppBreakpoints.desktop;

            return Stack(
              children: [
                // ── PageView ───────────────────────────────────────────────
                PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) => _OnboardingPage(
                    data: _pages[i],
                    isWide: isWide,
                    dotsCount: _pages.length,
                    dotsCurrent: _currentPage,
                    isLast: isLast,
                    onNext: _next,
                  ),
                ),

                // ── Кнопка «Пропустить» ────────────────────────────────────
                if (!isLast)
                  Positioned(
                    top: AppSpacing.sp16,
                    right: isWide ? AppSpacing.sp32 : AppSpacing.sp20,
                    child: TextButton(
                      onPressed: _goToTaxMode,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        textStyle: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Пропустить'),
                    ),
                  ),

                // ── Нижняя зона: точки + кнопка (только на телефоне —
                // на десктопе точки и CTA встроены в текстовую панель) ──────
                if (!isWide)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sp20,
                        0,
                        AppSpacing.sp20,
                        AppSpacing.sp32,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _DotIndicator(
                            count: _pages.length,
                            current: _currentPage,
                          ),
                          const SizedBox(height: AppSpacing.sp20),
                          _CtaButton(isLast: isLast, onPressed: _next),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Кнопка «Далее»/«Начать» — общая для мобильной нижней панели и
/// встроенного CTA в текстовой колонке широкого сплит-скрина.
class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.isLast, required this.onPressed});

  final bool isLast;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Единственный "второй" зелёный градиентный элемент экрана (первый —
    // основная иконка иллюстрации) — намеренно не через глобальную тему
    // FilledButton (та остаётся плоской заливкой accent для всех обычных
    // кнопок приложения), а точечно здесь, как просит Этап 3 для CTA
    // онбординга. FilledButton не умеет градиентную заливку, поэтому
    // Material+InkWell поверх Container с gradient — стандартный приём.
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.glow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLast ? 'Начать' : 'Далее',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onAccent,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: AppColors.onAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Один слайд ──────────────────────────────────────────────────────────────

class _OnboardingPage extends StatefulWidget {
  const _OnboardingPage({
    required this.data,
    required this.isWide,
    required this.dotsCount,
    required this.dotsCurrent,
    required this.isLast,
    required this.onNext,
  });

  final _PageData data;
  final bool isWide;
  final int dotsCount;
  final int dotsCurrent;
  final bool isLast;
  final VoidCallback onNext;

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isWide) {
      // Десктоп/веб: полноэкранный сплит — иллюстрация во всю высоту
      // левой панели, текст+точки+CTA по центру правой. Обе панели
      // растянуты на весь экран (CrossAxisAlignment.stretch), никакой
      // узкой карточки по центру окна.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: _IllustrationZone(
              icon: widget.data.icon,
              pulseAnim: _pulseAnim,
              large: true,
            ),
          ),
          Expanded(
            flex: 6,
            // Полная высота панели, не "остров" по центру — иначе на
            // высоких десктоп-окнах контент выглядит потерянным в
            // пустоте. Три смысловых блока (тег / заголовок+подзаголовок
            // / точки+CTA) разнесены равномерно по всей высоте панели.
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp32,
                    vertical: AppSpacing.sp48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _TagChip(label: widget.data.tag),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.data.title,
                            style: AppTextStyles.displayHero.copyWith(
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sp12),
                          Text(
                            widget.data.subtitle,
                            style: AppTextStyles.bodyMedium.copyWith(
                              height: 1.65,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DotIndicator(
                            count: widget.dotsCount,
                            current: widget.dotsCurrent,
                          ),
                          const SizedBox(height: AppSpacing.sp24),
                          _CtaButton(
                            isLast: widget.isLast,
                            onPressed: widget.onNext,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Иллюстративная зона ───────────────────────────────────────────
        Expanded(
          flex: 10,
          child: _IllustrationZone(
            icon: widget.data.icon,
            pulseAnim: _pulseAnim,
          ),
        ),

        // ── Текстовая зона ────────────────────────────────────────────────
        Expanded(
          flex: 9,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sp20,
              AppSpacing.sp20,
              AppSpacing.sp20,
              // нижний отступ оставляем для кнопки+точек из Stack
              132,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Тег-пилюля
                _TagChip(label: widget.data.tag),
                const SizedBox(height: AppSpacing.sp12),

                // Заголовок
                Text(
                  widget.data.title,
                  style: AppTextStyles.displayLarge.copyWith(
                    fontSize: 30,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp8),

                // Подзаголовок
                Text(
                  widget.data.subtitle,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w400,
                    height: 1.65,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Иллюстративная зона с кольцами и флоатинг-чипами ───────────────────────

class _IllustrationZone extends StatelessWidget {
  const _IllustrationZone({
    required this.icon,
    required this.pulseAnim,
    this.large = false,
  });

  final IconData icon;
  final Animation<double> pulseAnim;
  // Широкая desktop-панель заметно выше/шире мобильной — кольца и
  // основная иконка немного крупнее, чтобы композиция не терялась в
  // большой панели.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final ringScale = large ? 1.25 : 1.0;
    final iconSize = large ? 148.0 : 120.0;
    final chipInset = large ? 40.0 : 24.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.06),
            AppColors.background,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Внешнее кольцо
          _Ring(size: 280 * ringScale, opacity: 0.07),
          // Среднее кольцо
          _Ring(size: 210 * ringScale, opacity: 0.10),
          // Внутреннее кольцо
          _Ring(size: 148 * ringScale, opacity: 0.14),

          // Флоатинг-чип: сумма налога — левый нижний
          Positioned(
            left: chipInset,
            bottom: chipInset * 2,
            child: _FloatCard(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Налог к уплате', style: AppTextStyles.overline),
                      Text(
                        '41 200 ₽',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Флоатинг-чип: режим — правый верхний
          Positioned(
            right: chipInset - 4,
            top: chipInset + 20,
            child: _FloatChip(icon: Icons.shield_rounded, label: 'УСН 6%'),
          ),

          // Флоатинг-чип: доход — правый нижний
          Positioned(
            right: chipInset - 4,
            bottom: chipInset + 20,
            child: _FloatChip(
              icon: Icons.trending_up_rounded,
              label: '+241 000 ₽',
            ),
          ),

          // Основная иконка с пульсацией
          ScaleTransition(
            scale: pulseAnim,
            child: Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(large ? 40 : 36),
                boxShadow: AppShadows.glow,
              ),
              child: Icon(
                icon,
                size: large ? 64 : 52,
                color: AppColors.onAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Вспомогательные виджеты ─────────────────────────────────────────────────

/// Декоративное кольцо вокруг иконки
class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: opacity),
          width: 1,
        ),
      ),
    );
  }
}

/// Белая карточка с тенью (используется в иллюстративной зоне)
class _FloatCard extends StatelessWidget {
  const _FloatCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.12)),
        boxShadow: AppShadows.glowSoft,
      ),
      child: child,
    );
  }
}

/// Маленький пилюля-чип с иконкой (верхний правый, нижний правый)
class _FloatChip extends StatelessWidget {
  const _FloatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.captionBold.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

/// Тег-пилюля над заголовком
class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              letterSpacing: 0.4,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Точки пагинации: активная — вытянутая пилюля 28×8, остальные — 8×8
class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : AppColors.divider,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        );
      }),
    );
  }
}
