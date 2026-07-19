/// Единый источник текста трёх шагов онбординга — mobile и desktop
/// рендерят один и тот же контент, чтобы копия не расходилась между
/// платформами (см. .claude/skills/flutter-onboarding-green-orange).
class OnbStep {
  final String navLabel;
  final String chip;
  final bool chipOrange;
  final String title;
  final String accent;
  final String desc;

  const OnbStep({
    required this.navLabel,
    required this.chip,
    required this.chipOrange,
    required this.title,
    required this.accent,
    required this.desc,
  });
}

const onboardingSteps = [
  OnbStep(
    navLabel: 'Расчёт налога',
    chip: 'Автоматический расчёт',
    chipOrange: false,
    title: 'Считаем налог ',
    accent: 'за вас',
    desc: 'Загружаем выписку из банка и сами вычисляем налог по вашей '
        'системе — УСН, НПД, ОСНО и другим.',
  ),
  OnbStep(
    navLabel: 'Советы от ИИ',
    chip: 'Искусственный интеллект',
    chipOrange: true,
    title: 'Без ',
    accent: 'бухгалтерии',
    desc: 'ИИ классифицирует каждую операцию, даёт советы по оптимизации '
        'и предупреждает о рисках.',
  ),
  OnbStep(
    navLabel: 'Импорт из банков',
    chip: 'Банковские интеграции',
    chipOrange: false,
    title: 'Автоимпорт ',
    accent: 'операций',
    desc: 'Подключите свой банк один раз — доходы и расходы будут '
        'импортироваться автоматически, каждый день.',
  ),
];
