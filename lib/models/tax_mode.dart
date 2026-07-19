enum TaxMode { npd, usn6, usn15, ausn8, ausn20, osno, psn, eshn }

extension TaxModeExt on TaxMode {
  String get displayName {
    switch (this) {
      case TaxMode.npd:
        return 'Самозанятый (НПД)';
      case TaxMode.usn6:
        return 'УСН «Доходы»';
      case TaxMode.usn15:
        return 'УСН «Доходы − Расходы»';
      case TaxMode.ausn8:
        return 'АУСН «Доходы»';
      case TaxMode.ausn20:
        return 'АУСН «Доходы − Расходы»';
      case TaxMode.osno:
        return 'ОСНО';
      case TaxMode.psn:
        return 'ПСН (Патент)';
      case TaxMode.eshn:
        return 'ЕСХН';
    }
  }

  String get shortName {
    switch (this) {
      case TaxMode.npd:
        return 'НПД';
      case TaxMode.usn6:
        return 'УСН 6%';
      case TaxMode.usn15:
        return 'УСН 15%';
      case TaxMode.ausn8:
        return 'АУСН 8%';
      case TaxMode.ausn20:
        return 'АУСН 20%';
      case TaxMode.osno:
        return 'ОСНО';
      case TaxMode.psn:
        return 'ПСН';
      case TaxMode.eshn:
        return 'ЕСХН';
    }
  }

  String get description {
    switch (this) {
      case TaxMode.npd:
        return '4% с физлиц · 6% с юрлиц';
      case TaxMode.usn6:
        return '6% от доходов';
      case TaxMode.usn15:
        return '15% от (доходы − расходы)';
      case TaxMode.ausn8:
        return '8% от доходов';
      case TaxMode.ausn20:
        return '20% от (доходы − расходы)';
      case TaxMode.osno:
        return 'НДФЛ 13–22% + НДС 22%';
      case TaxMode.psn:
        return 'Фиксированный патент';
      case TaxMode.eshn:
        return '6% от (доходы − расходы)';
    }
  }

  String get detailedDescription {
    switch (this) {
      case TaxMode.npd:
        return 'Для самозанятых без работников. Не требует ведения бухгалтерии. Лимит — 2,4 млн ₽/год. Без страховых взносов.';
      case TaxMode.usn6:
        return 'Налог уменьшается на страховые взносы до 100%. Авансовые платежи ежеквартально. Лимит — 490,5 млн ₽/год.';
      case TaxMode.usn15:
        return 'Выгодна при расходах от 60% выручки. Минимальный налог — 1% от дохода. Авансы ежеквартально. Лимит — 490,5 млн ₽/год.';
      case TaxMode.ausn8:
        return 'Экспериментальный режим. Налог считает ФНС по данным банка и ККТ — декларация не нужна. Без страховых взносов за себя. До 5 сотрудников. Платежи ежемесячно до 25-го числа. Лимит — 60 млн ₽/год.';
      case TaxMode.ausn20:
        return 'Экспериментальный режим. Минимальный налог — 3% от дохода. Без страховых взносов за себя и деклараций. До 5 сотрудников. Платежи ежемесячно до 25-го числа. Лимит — 60 млн ₽/год.';
      case TaxMode.osno:
        return 'Прогрессивный НДФЛ 13–22%. НДС 22%. Обязательная отчётность. Подходит для работы с крупными юрлицами.';
      case TaxMode.psn:
        return 'Фиксированный патент на 1–12 месяцев. Без деклараций. Подходит для торговли и услуг. Лимит — 20 млн ₽/год.';
      case TaxMode.eshn:
        return 'Для производителей сельхозпродукции. Налог 6% от прибыли. Платежи дважды в год: июль и март.';
    }
  }

  double? get incomeLimit {
    switch (this) {
      case TaxMode.npd:
        return 2_400_000;
      case TaxMode.usn6:
      case TaxMode.usn15:
        return 490_500_000;
      case TaxMode.psn:
        return 20_000_000;
      case TaxMode.ausn8:
      case TaxMode.ausn20:
        return 60_000_000;
      case TaxMode.osno:
      case TaxMode.eshn:
        return null;
    }
  }

  // НПД и АУСН не платят фиксированные страховые взносы за себя
  bool get hasInsurance {
    switch (this) {
      case TaxMode.npd:
      case TaxMode.ausn8:
      case TaxMode.ausn20:
        return false;
      default:
        return true;
    }
  }

  // НПД и АУСН — ежемесячные платежи, остальные — квартальные авансы
  bool get isQuarterly {
    switch (this) {
      case TaxMode.npd:
      case TaxMode.ausn8:
      case TaxMode.ausn20:
        return false;
      default:
        return true;
    }
  }

  String get periodLabel => isQuarterly ? 'квартал' : 'месяц';

  // Подпись "среднего" слота переключателя периода (Месяц/•••/Год) —
  // у всех режимов это квартал, у ЕСХН официального квартального периода
  // в НК РФ нет (только полугодие, ст. 346.7 п. 2 НК РФ), см.
  // core/tax_payment_flexibility.dart.
  String get midPeriodLabel => this == TaxMode.eshn ? 'Полугодие' : 'Квартал';
}
