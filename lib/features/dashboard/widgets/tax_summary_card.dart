import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../main.dart';
import '../../../models/tax_mode.dart';

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
    final result = state.currentTaxResult;
    final dueFmt = DateFormat('d MMM', 'ru_RU').format(state.paymentDue);

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
            'Налог за ${state.currentPeriodLabel}'.toUpperCase(),
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

          const SizedBox(height: 10),

          // Налог — самостоятельный обязательный платёж. НЕ суммируется со
          // страховыми взносами: разная правовая природа и разные КБК,
          // поэтому на экране это отдельная сумма, а не общий "итог".
          _CountUpAmount(
            value: result.netTax,
            style: AppTextStyles.amount.copyWith(color: AppColors.onGradient),
          ),
          if (result.insuranceDeduction > 0) ...[
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

          // Доход / Расход + бейдж режима
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: _MiniStat(
                  label: 'Доход',
                  value: state.currentIncome.rub,
                ),
              ),
              const SizedBox(width: AppSpacing.sp24),
              Flexible(
                child: _MiniStat(
                  label: 'Расход',
                  value: state.currentExpenses.rub,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.onGradientAlpha(AppColors.fillOnGradient18),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  state.taxMode.shortName,
                  style: AppTextStyles.labelSmall.copyWith(
                    letterSpacing: 0,
                    color: AppColors.onGradient,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Страховые взносы, НДС, НДФЛ сверх лимита НПД, остаток вычета
          // НПД — каждый обязательный платёж отдельной строкой (разная
          // правовая природа и КБК, чем у налога netTax).
          if (result.monthlyInsurance > 0)
            _PaymentLine(
              label: 'Страховые взносы ≈/мес',
              value: result.monthlyInsurance.rub,
            ),
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
// белой полупрозрачной подложке поверх градиента.
class _PaymentLine extends StatelessWidget {
  final String label;
  final String value;
  const _PaymentLine({required this.label, required this.value});

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
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onGradientAlpha(AppColors.onGradientPrimary),
                fontWeight: FontWeight.w500,
              ),
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
