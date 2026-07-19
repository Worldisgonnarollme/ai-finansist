import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hover_cursor.dart';
import '../../../main.dart';
import '../../../models/payment_period.dart';
import '../../../models/tax_mode.dart';
import '../../../models/transaction.dart';

/// Dashboard hero card ("variant 1" — gradient treatment). Shows the tax
/// amount, deadline/progress, income vs expense split and the stack of
/// obligatory-payment lines (insurance, VAT, НДФЛ over the НПД limit, НПД
/// deduction remaining). Everything on this card sits on the green
/// gradient, so text uses the on-gradient (white/alpha) token ladder —
/// never `AppColors.textPrimary`, which is near-black and would be
/// unreadable here.
///
/// Risk/limit warnings and the НДФЛ-scale note are NOT rendered inside this
/// card (see [dashboard.dart]) — the redesign moves them below the hero,
/// as their own light-warning banners, matching the new design's layout.
class TaxSummaryCard extends StatelessWidget {
  final AppState state;
  const TaxSummaryCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final result = state.selectedPeriodTaxResult;
    final dueFmt = DateFormat('d MMM', 'ru_RU').format(state.paymentDue);
    // ПСН не облагает доход вообще — patentAnnualCost фиксирован и не
    // зависит от операций/выписок, поэтому это НЕ "налог с дохода" в том
    // смысле, в каком им является netTax для остальных режимов. Показывать
    // его в главной сумме означало бы: без единой операции пользователь на
    // патенте видел бы ненулевой "Налог", а пользователь на УСН/НПД/ОСНО —
    // корректный 0. Стоимость патента показывается отдельной строкой ниже,
    // как и страховые взносы (см. _PaymentLine).
    final isPsn = state.taxMode == TaxMode.psn;
    final heroTax = isPsn ? 0.0 : result.netTax;
    // На АУСН строку "Страховые взносы" составляет только травматизм
    // (125-ФЗ, ежемесячный срок — 15-е число) — у него нет ни ст. 430 НК
    // РФ, ни годового платежа, поэтому подпись про "платёж годовой"
    // (актуальную для фиксированных взносов ИП «за себя» на остальных
    // режимах) для АУСН показывать нельзя, это была бы неверная отсылка.
    final isAusn = state.taxMode == TaxMode.ausn8 || state.taxMode == TaxMode.ausn20;

    // Доход/расход рядом с суммой налога должны считаться по тому же
    // диапазону операций, что и сама сумма (selectedPeriodTxs) — иначе
    // при выборе "Год" налог показывал бы годовую сумму рядом с доходом
    // всего за один месяц, что визуально не сходилось бы.
    final periodTxs = state.selectedPeriodTxs;
    final periodIncome = periodTxs
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final periodExpenses = periodTxs
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sp20),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Период и предупреждение об устаревших данных
          Text(
            'Налог за ${state.selectedPeriodLabel}'.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onGradientAlpha(AppColors.onGradientFaint),
            ),
          ),
          if (!state.isShowingCurrentMonth)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sp4),
              child: Text(
                'Текущий ${state.taxMode.periodLabel} без операций — показан последний период с данными',
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                  color: AppColors.onGradientAlpha(0.6),
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.sp12),
          _PeriodSelector(state: state),

          const SizedBox(height: 10),

          // Налог — самостоятельный обязательный платёж. НЕ суммируется со
          // страховыми взносами: разная правовая природа и разные КБК,
          // поэтому на экране это отдельная сумма, а не общий "итог". На
          // ПСН здесь всегда 0 — см. heroTax выше, патент показан отдельной
          // строкой ниже вместе со взносами.
          _CountUpAmount(
            value: heroTax,
            style: AppTextStyles.amount.copyWith(color: AppColors.onGradient),
          ),
          if (!isPsn && result.insuranceDeduction > 0) ...[
            const SizedBox(height: AppSpacing.sp4 + 2),
            Text(
              'С учётом вычета взносов',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.onGradientAlpha(AppColors.onGradientMuted),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (result.npdDeductionUsed > 0) ...[
            const SizedBox(height: AppSpacing.sp4 + 2),
            Text(
              '−${result.npdDeductionUsed.rub} налоговый вычет НПД',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.onGradientAlpha(AppColors.onGradientMuted),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Срок оплаты + прогресс
          _PaymentProgress(paymentDue: state.paymentDue, dueLabel: dueFmt),

          const SizedBox(height: 16),
          Divider(color: AppColors.onGradientAlpha(0.18), height: 1),
          const SizedBox(height: 16),

          // Доход / Расход
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: _MiniStat(label: 'Доход', value: periodIncome.rub),
              ),
              const SizedBox(width: AppSpacing.sp24),
              Flexible(
                child: _MiniStat(label: 'Расход', value: periodExpenses.rub),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Стоимость патента, страховые взносы, НДС, НДФЛ сверх лимита
          // НПД, остаток вычета НПД — каждый обязательный платёж отдельной
          // строкой (разная правовая природа и КБК). Патент — фиксированная
          // сумма (годовая ставка ÷ 12, за вычетом взносов), не зависящая
          // от дохода, поэтому не входит в главную сумму (heroTax) выше.
          if (isPsn && result.netTax > 0)
            _PaymentLine(
              label: 'Патент ≈/мес (за вычетом взносов)',
              value: result.netTax.rub,
            ),
          // Ст. 430 НК РФ формально требует платить взносы ИП «за себя»
          // раз в год (фикс. часть — до 31 декабря, доп. 1% — до 1 июля
          // следующего года), но ст. 45 НК РФ п. 1 разрешает платить
          // досрочно частями — и ФНС сама рекомендует вносить их
          // поквартально, чтобы сразу уменьшать налог того же периода
          // (см. советы AiService для УСН/АУСН). Поэтому здесь показана
          // не месячная, а квартальная сумма — с пояснением ниже, что это
          // не отдельный обязательный срок, а способ платить удобнее. На
          // АУСН эта строка — только взнос на травматизм (125-ФЗ), у
          // которого совсем другой, ежемесячный срок — см. isAusn выше.
          if (result.monthlyInsurance > 0) ...[
            _PaymentLine(
              label: 'Страховые взносы ≈/квартал',
              value: (result.monthlyInsurance * 3).rub,
              onInfoTap: () => _showInsuranceLegalSheet(context, state.taxMode),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sp8),
              child: Text(
                isAusn
                    ? 'Взнос на травматизм (125-ФЗ) — ежемесячно, до 15-го числа'
                    : 'Платёж годовой (ст. 430 НК РФ) — поквартально показано для удобства',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onGradientAlpha(AppColors.onGradientMuted),
                ),
              ),
            ),
          ],
          if (result.vatTax > 0)
            _PaymentLine(label: 'НДС за период', value: result.vatTax.rub),
          if (result.ndflOverLimitTax > 0)
            _PaymentLine(
              label: 'НДФЛ сверх лимита НПД',
              value: result.ndflOverLimitTax.rub,
            ),
          // Остаток налогового вычета НПД (даётся один раз, 10 000 ₽,
          // снижает ставку 4%→3% / 6%→4% до полного исчерпания) —
          // показывается всегда на НПД, чтобы был виден общий остаток.
          if (state.taxMode == TaxMode.npd)
            _PaymentLine(
              label: 'Остаток вычета НПД',
              value: result.npdDeductionRemaining.rub,
            ),
        ],
      ),
    );
  }
}

// Текст для вопросика рядом со строкой "Страховые взносы" — на АУСН
// фиксированных взносов ИП «за себя» нет вообще (только травматизм, и это
// другой закон), поэтому пояснение зависит от режима.
const _fixedInsuranceLegalText =
    'Фиксированные страховые взносы ИП «за себя» — ст. 430 НК РФ:\n\n'
    '• Фиксированная часть — 57 390 ₽ в год (п. 1.2 ст. 430 НК РФ). Не '
    'зависит от дохода и факта ведения деятельности — платится, даже если '
    'операций не было.\n\n'
    '• Дополнительный взнос — 1% с дохода свыше 300 000 ₽ в год, но не '
    'более 321 818 ₽ (п. 1.2 ст. 430 НК РФ).\n\n'
    'Сроки: фиксированная часть — до 31 декабря текущего года, '
    'дополнительный 1% — до 1 июля следующего года (п. 2 ст. 432 НК РФ).';

const _ausnInsuranceLegalText =
    'На АУСН фиксированные взносы ИП «за себя» (ОПС, ОМС, ВНиМ) не '
    'платятся — ст. 18 Федерального закона от 25.02.2022 № 17-ФЗ.\n\n'
    'Эту сумму составляет только обязательный взнос на травматизм — '
    '2 959 ₽ в год за весь штат, не зависит от числа сотрудников '
    '(Федеральный закон от 24.07.1998 № 125-ФЗ). Платится напрямую в '
    'СФР до 15-го числа каждого месяца — не через ЕНС.';

void _showInsuranceLegalSheet(BuildContext context, TaxMode mode) {
  final isAusn = mode == TaxMode.ausn8 || mode == TaxMode.ausn20;
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    // Текст с точными статьями закона может не поместиться в дефолтную
    // высоту (до половины экрана) на невысоких экранах/при увеличенном
    // системном шрифте — isScrollControlled позволяет шторке вырасти, а
    // SingleChildScrollView ниже подстрахует, если и этого не хватит.
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.sp20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Почему такая сумма',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sp12),
            Text(
              isAusn ? _ausnInsuranceLegalText : _fixedInsuranceLegalText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sp20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Понятно'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Переключатель периода отображения (Месяц/Квартал·Полугодие/Год) — только
// отображение, реальный срок уплаты (paymentDue) от него не зависит.
// Недопустимые для текущего режима периоды (см.
// core/tax_payment_flexibility.dart) не убираются с экрана, а показываются
// затемнёнными, некликабельными и с иконкой замка — причина видна по
// долгому нажатию/наведению (Tooltip), чтобы пользователь понимал, ПОЧЕМУ
// нельзя, а не просто не видел вариант.
class _PeriodSelector extends StatelessWidget {
  final AppState state;
  const _PeriodSelector({required this.state});

  @override
  Widget build(BuildContext context) {
    final flex = state.paymentFlexibility;
    final current = state.paymentPeriod;
    final options = [
      PaymentPeriod.month,
      PaymentPeriod.quarter,
      PaymentPeriod.year,
    ];
    final labels = {
      PaymentPeriod.month: 'Месяц',
      PaymentPeriod.quarter: state.taxMode.midPeriodLabel,
      PaymentPeriod.year: 'Год',
    };

    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sp8 - 2),
          Expanded(
            child: _PeriodPill(
              label: labels[options[i]]!,
              selected: current == options[i],
              allowed: flex.allows(options[i]),
              note: flex.noteFor(options[i]),
              onTap: () => state.setPaymentPeriod(options[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _PeriodPill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool allowed;
  final String? note;
  final VoidCallback onTap;

  const _PeriodPill({
    required this.label,
    required this.selected,
    required this.allowed,
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppColors.onGradient
        : AppColors.onGradientAlpha(AppColors.fillOnGradient12);
    final fg = selected
        ? AppColors.accentDark
        : AppColors.onGradientAlpha(
            allowed ? AppColors.onGradientPrimary : 0.4,
          );

    final pill = Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!allowed) ...[
            Icon(Icons.lock_outline_rounded, size: 11, color: fg),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.captionBold.copyWith(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (!allowed) {
      return Tooltip(
        message: note ?? 'Недоступно для текущего налогового режима',
        triggerMode: TooltipTriggerMode.tap,
        child: pill,
      );
    }
    return HoverCursor(
      child: GestureDetector(onTap: onTap, child: pill),
    );
  }
}

/// Сумма налога "набегает" от 0 до значения один раз при первом появлении
/// карточки на экране, а не при каждом обновлении AppState — иначе она
/// дёргалась бы при любом не связанном изменении данных (что раздражает).
/// AnimationController живёт в State и создаётся только в initState (один
/// раз за время жизни виджета), поэтому повторные build() от Provider не
/// перезапускают анимацию — после её завершения текст всегда показывает
/// актуальное widget.value напрямую.
class _CountUpAmount extends StatefulWidget {
  final double value;
  final TextStyle style;
  const _CountUpAmount({required this.value, required this.style});

  @override
  State<_CountUpAmount> createState() => _CountUpAmountState();
}

class _CountUpAmountState extends State<_CountUpAmount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _anim = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final displayed = _ctrl.isCompleted ? widget.value : _anim.value;
        return Text(displayed.rub, style: widget.style);
      },
    );
  }
}

class _PaymentProgress extends StatelessWidget {
  final DateTime paymentDue;
  final String dueLabel;
  const _PaymentProgress({required this.paymentDue, required this.dueLabel});

  @override
  Widget build(BuildContext context) {
    final daysLeft = paymentDue.difference(DateTime.now()).inDays.clamp(0, 90);
    final progress = (90 - daysLeft) / 90.0;
    // Срочность — тот же порог (≤7 дней), что и в остальном приложении.
    // На градиентной карточке "срочный" цвет — не rust (плохо читается на
    // зелёном), а сплошной белый на фоне полупрозрачного трека.
    final urgent = daysLeft <= 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Срок оплаты: $dueLabel',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onGradientAlpha(0.9),
              ),
            ),
            Text(
              '$daysLeft дн.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onGradientAlpha(0.9),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.onGradientAlpha(
              AppColors.fillOnGradient22,
            ),
            valueColor: AlwaysStoppedAnimation(
              urgent
                  ? AppColors.onGradient
                  : AppColors.onGradientAlpha(AppColors.onGradientPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.onGradientAlpha(0.7),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.amountSmall.copyWith(
            color: AppColors.onGradient,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// Строка обязательного платежа (взносы/НДС/НДФЛ/остаток вычета) — pill на
// белой полупрозрачной подложке поверх градиента. onInfoTap — необязательный
// вопросик рядом с подписью (сейчас используется только для строки
// страховых взносов — см. _showInsuranceLegalSheet), открывающий bottom
// sheet с конкретными статьями закона, почему именно такая сумма/срок.
class _PaymentLine extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onInfoTap;
  const _PaymentLine({
    required this.label,
    required this.value,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sp8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.onGradientAlpha(AppColors.fillOnGradient12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onGradientAlpha(
                        AppColors.onGradientPrimary,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (onInfoTap != null)
                  HoverCursor(
                    child: GestureDetector(
                      onTap: onInfoTap,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Icon(
                          Icons.help_outline_rounded,
                          size: 15,
                          color: AppColors.onGradientAlpha(
                            AppColors.onGradientMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sp8),
          Text(
            value,
            style: AppTextStyles.amountTiny.copyWith(
              color: AppColors.onGradient,
            ),
          ),
        ],
      ),
    );
  }
}
