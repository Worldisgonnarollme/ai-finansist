import '../models/payment_period.dart';
import '../models/tax_mode.dart';

/// Можно ли по этому налоговому режиму платить помесячно / за квартал
/// (у ЕСХН — "квартальный" слот означает полугодие, см.
/// TaxModeExt.midPeriodLabel) / за год вперёд — источник истины строго по
/// НК РФ / ФЗ-422 / ФЗ-17, без придуманных графиков (см. ст. 45 НК РФ, п.
/// 1 — общее право досрочной уплаты, и профильные статьи по каждому
/// режиму ниже). [monthNote]/[quarterNote]/[yearNote] — причина, почему
/// период недоступен (используется только если соответствующий флаг
/// false).
class PaymentFlexibility {
  final bool month;
  final bool quarter;
  final bool year;
  final String? monthNote;
  final String? quarterNote;
  final String? yearNote;

  const PaymentFlexibility({
    required this.month,
    required this.quarter,
    required this.year,
    this.monthNote,
    this.quarterNote,
    this.yearNote,
  });

  bool allows(PaymentPeriod p) => switch (p) {
    PaymentPeriod.month => month,
    PaymentPeriod.quarter => quarter,
    PaymentPeriod.year => year,
  };

  String? noteFor(PaymentPeriod p) => switch (p) {
    PaymentPeriod.month => monthNote,
    PaymentPeriod.quarter => quarterNote,
    PaymentPeriod.year => yearNote,
  };
}

class TaxPaymentFlexibility {
  TaxPaymentFlexibility._();

  static PaymentFlexibility of(TaxMode mode) {
    switch (mode) {
      // НПД — ст. 11, п. 3 ФЗ № 422-ФЗ: только помесячно, сумма считается
      // автоматически по факту месяца — ни квартального шага, ни оплаты
      // вперёд за год не существует.
      case TaxMode.npd:
        return const PaymentFlexibility(
          month: true,
          quarter: false,
          year: false,
          quarterNote:
              'У НПД нет квартального платежа — налог считается и уплачивается только помесячно (ст. 11 ФЗ № 422-ФЗ)',
          yearNote:
              'Нельзя оплатить за год вперёд — сумма налога известна только по факту каждого месяца',
        );

      // АУСН — ст. 12, п. 2 ФЗ № 17-ФЗ: расчёт и списание только
      // помесячные, ФНС сама считает налог по данным банка и ККТ.
      case TaxMode.ausn8:
      case TaxMode.ausn20:
        return const PaymentFlexibility(
          month: true,
          quarter: false,
          year: false,
          quarterNote:
              'У АУСН нет квартального платежа — расчёт и списание только помесячные (ст. 12 ФЗ № 17-ФЗ)',
          yearNote:
              'Нельзя оплатить за год вперёд — сумма налога известна только по факту месяца',
        );

      // УСН — ст. 346.21, п. 7 НК РФ: официальный шаг — квартальные
      // авансы; помесячно можно добровольно пополнять ЕНС (ст. 45, п. 1
      // НК РФ); за год вперёд нельзя — точный доход неизвестен заранее.
      case TaxMode.usn6:
      case TaxMode.usn15:
        return const PaymentFlexibility(
          month: true,
          quarter: true,
          year: false,
          yearNote:
              'Нельзя оплатить за год вперёд — точный доход известен только по итогам года',
        );

      // ПСН — ст. 346.51, п. 2 НК РФ: стоимость патента фиксирована и не
      // зависит от фактического дохода, поэтому доступны любые сроки —
      // от одного платежа сразу при получении патента до помесячного
      // пополнения ЕНС.
      case TaxMode.psn:
        return const PaymentFlexibility(month: true, quarter: true, year: true);

      // ОСНО — НДФЛ ИП (ст. 227, п. 6, 8 НК РФ) и НДС (ст. 174, п. 1
      // НК РФ) дают одинаковую матрицу: квартал — официальный шаг (у
      // НДФЛ — авансы 28 апреля/июля/октября; у НДС — можно досрочно
      // закрыть всю сумму квартала первым платежом), месяц — доступен
      // (у НДС — обязательные платежи по 1/3, у НДФЛ — добровольный
      // аванс), год вперёд — нельзя: итоговая сумма НДФЛ известна только
      // по итогам года (15 июля следующего года).
      case TaxMode.osno:
        return const PaymentFlexibility(
          month: true,
          quarter: true,
          year: false,
          yearNote:
              'Нельзя оплатить за год вперёд — итоговая сумма НДФЛ известна только по итогам года (ст. 227 НК РФ)',
        );

      // ЕСХН — ст. 346.7, п. 2 и ст. 346.9 НК РФ: официальные периоды —
      // только полугодие (аванс до 28 июля) и год (итог до 28 марта);
      // отдельного квартального отчётного периода в НК РФ нет — "средний"
      // слот здесь показывается как "Полугодие" (TaxModeExt.midPeriodLabel).
      // Месяц доступен только как добровольное пополнение ЕНС (ст. 45,
      // п. 1 НК РФ), год вперёд — нельзя, база считается нарастающим
      // итогом и известна только по факту года (ст. 346.9, п. 5 НК РФ).
      case TaxMode.eshn:
        return const PaymentFlexibility(
          month: true,
          quarter: true,
          year: false,
          yearNote:
              'Нельзя оплатить за год вперёд — сумма считается нарастающим итогом и известна только по факту года (ст. 346.9 НК РФ)',
        );
    }
  }
}
