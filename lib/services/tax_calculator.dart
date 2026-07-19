import 'dart:math' as math;
import '../models/transaction.dart';
import '../models/tax_period.dart';
import '../models/tax_mode.dart';
import '../models/tax_settings.dart';
import '../models/tax_result.dart';

class _DeductionResult {
  final double tax;
  final double deductionUsed;
  final double remainingBalance;

  const _DeductionResult({
    required this.tax,
    required this.deductionUsed,
    required this.remainingBalance,
  });
}

class TaxCalculator {
  // Страховые взносы ИП за себя 2026
  static const double _insuranceFixed = 57_390.0;
  static const double _insuranceThreshold = 300_000.0;
  static const double _insuranceAdditionalRate = 0.01;
  static const double _insuranceAdditionalMax = 321_818.0;

  // НДС для УСН 2026: поэтапное введение по порогам годового дохода
  // (закон о постепенной отмене освобождения от НДС на УСН).
  // До 20 млн — НДС не платится; 20–272,5 млн — льготная ставка 5% без
  // права на вычеты; 272,5–490,5 млн — льготная ставка 7% без права на
  // вычеты; свыше 490,5 млн — полная потеря права на УСН (переход на
  // ОСНО с начала квартала превышения).
  static const double _usnVatFreeThreshold = 20_000_000.0;
  static const double _usnVat5Threshold = 272_500_000.0;
  static const double _usnVat7Threshold = 490_500_000.0;
  static const double _usnVat5Rate = 0.05;
  static const double _usnVat7Rate = 0.07;

  // Лимит остаточной стоимости основных средств для УСН (ст. 346.12 НК РФ)
  static const double _usnFixedAssetsLimit = 218_000_000.0;

  // Лимит НПД и максимальный налоговый вычет (ст. 12 422-ФЗ)
  static const double _npdLimit = 2_400_000.0;
  static const double _npdMaxDeduction = 10_000.0;

  // АУСН освобождает ИП от фиксированных взносов на ОПС/ОМС/ВНиМ "за себя"
  // (mode.hasInsurance == false), но НЕ от взноса на травматизм — это
  // отдельное обязательство по 125-ФЗ (не глава 34 НК РФ, не через ЕНС, а
  // напрямую в СФР), которое реформа ЕНП 2023 года не затронула. На АУСН
  // это фиксированная сумма за весь штат (не зависит от числа сотрудников
  // и их зарплат), не уменьшает сам налог АУСН — отдельная строка.
  // Источник: справочная карточка режима АУСН в приложении (уже верно
  // описывала эту сумму текстом — здесь она наконец учтена в расчёте) +
  // docs/research_insurance_contributions.md.
  static const double _ausnInjuryAnnual = 2_959.0;

  // ── Главный метод расчёта ────────────────────────────────
  // periodMonths — сколько календарных месяцев занимает переданный
  // periodTransactions (1 — месяц, 3 — квартал, 6 — полугодие, 12 — год).
  // Используется ТОЛЬКО режимами, чья "базовая" сумма не выводится из
  // суммы periodTransactions напрямую (ПСН — фиксированная стоимость
  // патента; вычет взносов УСН 6% — сам взнос месячный, а не из операций)
  // — остальные режимы считают gross/net от income/expenses периода и
  // корректно масштабируются простой заменой periodTransactions без
  // этого параметра. По умолчанию 1 — поведение всех существующих
  // вызовов (currentTaxResult и т.п.) не меняется.
  static TaxResult calculate({
    required List<Transaction> periodTransactions,
    required double annualIncome,
    required TaxMode mode,
    required TaxSettings settings,
    double npdDeductionRemaining = _npdMaxDeduction,
    int? year,
    int periodMonths = 1,
  }) {
    final resolvedYear = year ?? DateTime.now().year;
    // Pre-validation policy (источник истины: НК РФ, разъяснения ФНС):
    // taxable → участвует в расчёте; non_taxable → исключается;
    // undefined → НЕ участвует автоматически, требует ручной разметки.
    // Приложение не принимает налоговых решений за пользователя — расчёт
    // продолжается на основе уже размеченных операций, а неразмеченные
    // только выставляют предупреждение.
    final taxablePeriodTxs = periodTransactions
        .where((t) => t.taxRelevance == TaxRelevance.taxable)
        .toList();
    final undefinedCount = periodTransactions
        .where((t) => t.taxRelevance == TaxRelevance.undefined)
        .length;

    final income = _income(taxablePeriodTxs);
    final expenses = _expenses(taxablePeriodTxs);
    final fromIndividuals = _fromIndividuals(taxablePeriodTxs);
    final fromLegal = _fromLegal(taxablePeriodTxs);
    final fromUnclassified = _fromUnclassified(taxablePeriodTxs);

    final result = switch (mode) {
      TaxMode.npd => _npd(
        fromIndividuals,
        fromLegal,
        fromUnclassified,
        annualIncome,
        npdDeductionRemaining,
      ),
      TaxMode.usn6 => _usn6(
        income,
        annualIncome,
        settings,
        resolvedYear,
        periodMonths,
      ),
      TaxMode.usn15 => _usn15(
        income,
        expenses,
        annualIncome,
        settings,
        resolvedYear,
      ),
      TaxMode.ausn8 => _ausn8(income, annualIncome),
      TaxMode.ausn20 => _ausn20(income, expenses, annualIncome),
      TaxMode.osno => _osno(
        income,
        annualIncome,
        settings,
        undefinedCount,
        resolvedYear,
      ),
      TaxMode.psn => _psn(annualIncome, settings, resolvedYear, periodMonths),
      TaxMode.eshn => _eshn(
        income,
        expenses,
        annualIncome,
        settings,
        resolvedYear,
      ),
    };

    final empMsg = _employeeLimitMsg(mode, settings);
    return result
        .withUndefinedCount(undefinedCount)
        .withEmployeeLimit(warning: empMsg != null, message: empMsg);
  }

  // ── НПД: 4%/6% с вычетом 10 000 ₽ и лимитом 2,4 млн ───
  static TaxResult _npd(
    double fromInd,
    double fromLegal,
    double fromUnclassified,
    double annualIncome,
    double deductionRemaining,
  ) {
    // Ставка НПД (4%/6%) НЕ меняется и не пересчитывается задним числом
    // при достижении лимита — лимит 2,4 млн только выставляет
    // предупреждение (incomeLimitWarning). Решение о смене режима при
    // превышении лимита принимает пользователь. Но доход СВЕРХ лимита
    // выходит из-под действия спецрежима НПД (ст. 4 422-ФЗ) — с этой
    // части физлицо обязано платить НДФЛ по прогрессивной шкале
    // (см. ndflOverLimitTax ниже), отдельно от налога НПД.
    final taxableInd = fromInd;
    final taxableLegal = fromLegal;
    final taxableUnclassified = fromUnclassified;

    // Применяем вычет: ФЛ 4%→3% (экономия 1%), ЮЛ/ИП 6%→4% (экономия 2%)
    double balance = deductionRemaining;
    double totalTax = 0;
    double totalDeductionUsed = 0;

    final indResult = _applyDeduction(taxableInd, 0.04, 0.01, balance);
    totalTax += indResult.tax;
    totalDeductionUsed += indResult.deductionUsed;
    balance = indResult.remainingBalance;

    final legalResult = _applyDeduction(taxableLegal, 0.06, 0.02, balance);
    totalTax += legalResult.tax;
    totalDeductionUsed += legalResult.deductionUsed;
    balance = legalResult.remainingBalance;

    // Неклассифицированный доход — консервативно 4%→3% (как физлицо)
    final unclassResult = _applyDeduction(
      taxableUnclassified,
      0.04,
      0.01,
      balance,
    );
    totalTax += unclassResult.tax;
    totalDeductionUsed += unclassResult.deductionUsed;
    balance = unclassResult.remainingBalance;

    final grossTax =
        taxableInd * 0.04 + taxableLegal * 0.06 + taxableUnclassified * 0.04;
    final pct = annualIncome / _npdLimit;

    // НДФЛ на доход сверх лимита 2,4 млн ₽/год (маржинально по периоду —
    // та же схема, что у ОСНО с НДФЛ/НДС): считаем прогрессивный НДФЛ
    // от суммы, накопленной сверх лимита, на начало и на конец периода,
    // разница — сумма к уплате именно за этот период.
    final periodIncome = taxableInd + taxableLegal + taxableUnclassified;
    final annualOverLimitTax = math.max(
      0.0,
      _ndfl(annualIncome) - _ndfl(_npdLimit),
    );
    final prevOverLimitTax = math.max(
      0.0,
      _ndfl(math.max(0.0, annualIncome - periodIncome)) - _ndfl(_npdLimit),
    );
    final ndflOverLimit = annualOverLimitTax - prevOverLimitTax;

    return TaxResult(
      grossTax: grossTax,
      netTax: totalTax,
      npdDeductionUsed: totalDeductionUsed,
      npdDeductionRemaining: balance,
      ndflOverLimitTax: ndflOverLimit,
      incomeLimitWarning: pct >= 0.8,
      incomeLimitPercent: pct,
      incomeLimitMessage: _limitMsg(annualIncome, _npdLimit, 'НПД'),
    );
  }

  // Применяет налоговый вычет к сумме дохода
  // fullRate — полная ставка, savingRate — экономия от вычета
  static _DeductionResult _applyDeduction(
    double income,
    double fullRate,
    double savingRate,
    double balance,
  ) {
    if (income <= 0) {
      return _DeductionResult(
        tax: 0,
        deductionUsed: 0,
        remainingBalance: balance,
      );
    }
    if (balance <= 0) {
      return _DeductionResult(
        tax: income * fullRate,
        deductionUsed: 0,
        remainingBalance: 0,
      );
    }
    final maxSavings = income * savingRate;
    if (maxSavings <= balance) {
      // Весь доход покрыт вычетом
      return _DeductionResult(
        tax: income * (fullRate - savingRate),
        deductionUsed: maxSavings,
        remainingBalance: balance - maxSavings,
      );
    } else {
      // Вычет исчерпывается в середине: делим на две части
      final withDeduction = balance / savingRate;
      final withoutDeduction = income - withDeduction;
      return _DeductionResult(
        tax:
            withDeduction * (fullRate - savingRate) +
            withoutDeduction * fullRate,
        deductionUsed: balance,
        remainingBalance: 0,
      );
    }
  }

  // ── Лимит численности сотрудников и ОС по режиму ────────
  // Возвращает текст предупреждения или null
  // (ст. 346.12, 346.13, 346.20, 346.43 НК РФ)
  static String? _employeeLimitMsg(TaxMode mode, TaxSettings settings) {
    final count = settings.employeeCount;
    switch (mode) {
      case TaxMode.npd:
        if (count > 0) {
          return 'НПД: наёмные сотрудники запрещены (ст. 4 422-ФЗ)';
        }
      case TaxMode.ausn8:
      case TaxMode.ausn20:
        if (count > 5) {
          return 'Превышен лимит АУСН: до 5 сотрудников (ст. 3 422-ФЗ)';
        }
      case TaxMode.psn:
        if (count > 15) {
          return 'Превышен лимит ПСН: до 15 сотрудников (ст. 346.43 НК РФ)';
        }
      case TaxMode.usn6:
      case TaxMode.usn15:
        // Система повышенных ставок (8%/20% при штате 101–130 человек)
        // отменена — базовая ставка действует вплоть до превышения
        // лимита численности.
        if (count > 130) {
          return 'Превышен лимит УСН: до 130 сотрудников (ст. 346.13 НК РФ)';
        }
        if (settings.fixedAssetsValue > _usnFixedAssetsLimit) {
          return 'Превышена остаточная стоимость ОС: лимит 218 млн ₽ '
              '(ст. 346.12 НК РФ) — утрата права на УСН';
        }
      case TaxMode.osno:
      case TaxMode.eshn:
        break;
    }
    return null;
  }

  // Накопленный НДС для УСН нарастающим итогом с начала года — кусочно-
  // линейная функция от годового дохода (аналогично _ndfl): 0 до 20 млн,
  // 5% на часть 20–272,5 млн, 7% на часть свыше 272,5 млн.
  static double _usnVatCumulative(double annualIncome) {
    if (annualIncome <= _usnVatFreeThreshold) return 0.0;
    if (annualIncome <= _usnVat5Threshold) {
      return (annualIncome - _usnVatFreeThreshold) * _usnVat5Rate;
    }
    final base5 = (_usnVat5Threshold - _usnVatFreeThreshold) * _usnVat5Rate;
    return base5 + (annualIncome - _usnVat5Threshold) * _usnVat7Rate;
  }

  // НДС за конкретный период — маржинально, той же схемой, что и
  // ndflOverLimitTax: разница накопленного НДС на конец и на начало
  // периода. Корректно делит период, даже если он пересёк порог.
  static double _usnVatForPeriod(double periodIncome, double annualIncome) {
    final prevAnnualIncome = math.max(0.0, annualIncome - periodIncome);
    return _usnVatCumulative(annualIncome) -
        _usnVatCumulative(prevAnnualIncome);
  }

  static String? _usnVatMessage(double annualIncome) {
    if (annualIncome <= _usnVatFreeThreshold) return null;
    if (annualIncome <= _usnVat5Threshold) {
      return 'Доход > 20 млн ₽ — льготный НДС 5% (без права на вычеты)';
    }
    if (annualIncome <= _usnVat7Threshold) {
      return 'Доход > 272,5 млн ₽ — льготный НДС 7% (без права на вычеты)';
    }
    return null; // свыше 490,5 млн — уже покрывается _limitMsg (потеря УСН)
  }

  // ── УСН 6% (Доходы): налог − страховые взносы ───────────
  static TaxResult _usn6(
    double income,
    double annualIncome,
    TaxSettings settings,
    int year,
    int periodMonths,
  ) {
    // Повышенная ставка 8% при штате 101–130 человек отменена — базовая
    // ставка действует вплоть до превышения лимита в 130 сотрудников
    // (ст. 346.13 НК РФ).
    final rate = settings.usn6Rate / 100;
    final gross = income * rate;
    final ins = _monthlyIns(annualIncome, settings, year);
    final annIns = _annualIns(annualIncome, settings, year);
    // Взносы, доступные к вычету ЗА ЭТОТ ПЕРИОД (не только за месяц) —
    // без periodMonths квартальный/годовой просмотр вычитал бы из
    // квартальной/годовой суммы налога только один месяц взносов и
    // занижал бы фактически положенный вычет (ст. 346.21, п. 3.1 НК РФ).
    final periodIns = ins * periodMonths;
    final maxDeduct = settings.hasEmployees ? gross * 0.5 : gross;
    final deduct = math.min(maxDeduct, periodIns);
    final net = math.max(0.0, gross - deduct);
    const limit = _usnVat7Threshold; // 490,5 млн — полная потеря права на УСН
    final pct = annualIncome / limit;
    final vat = _usnVatForPeriod(income, annualIncome);
    return TaxResult(
      grossTax: gross,
      insuranceDeduction: deduct,
      netTax: net,
      monthlyInsurance: ins,
      annualInsurance: annIns,
      vatApplicable: annualIncome > _usnVatFreeThreshold,
      vatTax: vat,
      incomeLimitWarning: pct >= 0.8,
      incomeLimitPercent: pct,
      incomeLimitMessage: annualIncome > limit
          ? _limitMsg(annualIncome, limit, 'УСН')
          : (_usnVatMessage(annualIncome) ??
                _limitMsg(annualIncome, limit, 'УСН')),
    );
  }

  // ── УСН 15% (Доходы − Расходы) ──────────────────────────
  static TaxResult _usn15(
    double income,
    double expenses,
    double annualIncome,
    TaxSettings settings,
    int year,
  ) {
    // Повышенная ставка 20% при штате 101–130 человек отменена — базовая
    // ставка действует вплоть до превышения лимита в 130 сотрудников
    // (ст. 346.13 НК РФ).
    final rate = settings.usn15Rate / 100;
    final base = math.max(0.0, income - expenses);
    final regular = base * rate;
    final minimum = income * 0.01;
    final gross = math.max(regular, minimum);
    final ins = _monthlyIns(annualIncome, settings, year);
    final annIns = _annualIns(annualIncome, settings, year);
    const limit = _usnVat7Threshold; // 490,5 млн — полная потеря права на УСН
    final pct = annualIncome / limit;
    final vat = _usnVatForPeriod(income, annualIncome);
    return TaxResult(
      grossTax: gross,
      netTax: gross,
      monthlyInsurance: ins,
      annualInsurance: annIns,
      vatApplicable: annualIncome > _usnVatFreeThreshold,
      vatTax: vat,
      incomeLimitWarning: pct >= 0.8,
      incomeLimitPercent: pct,
      incomeLimitMessage: annualIncome > limit
          ? _limitMsg(annualIncome, limit, 'УСН')
          : (_usnVatMessage(annualIncome) ??
                _limitMsg(annualIncome, limit, 'УСН')),
    );
  }

  // ── АУСН «Доходы»: 8%, без взносов и без вычетов ────────
  static TaxResult _ausn8(double income, double annualIncome) {
    final gross = income * 0.08;
    const limit = 60_000_000.0;
    final pct = annualIncome / limit;
    return TaxResult(
      grossTax: gross,
      netTax: gross,
      monthlyInsurance: _ausnInjuryAnnual / 12,
      annualInsurance: _ausnInjuryAnnual,
      incomeLimitWarning: pct >= 0.8,
      incomeLimitPercent: pct,
      incomeLimitMessage: _limitMsg(annualIncome, limit, 'АУСН'),
    );
  }

  // ── АУСН «Доходы − Расходы»: 20%, минимальный налог 3% ──
  // (минимальный налог здесь 3% от дохода — выше, чем 1% у обычной УСН 15%)
  static TaxResult _ausn20(
    double income,
    double expenses,
    double annualIncome,
  ) {
    final base = math.max(0.0, income - expenses);
    final regular = base * 0.20;
    final minimum = income * 0.03;
    final gross = math.max(regular, minimum);
    const limit = 60_000_000.0;
    final pct = annualIncome / limit;
    return TaxResult(
      grossTax: gross,
      netTax: gross,
      monthlyInsurance: _ausnInjuryAnnual / 12,
      annualInsurance: _ausnInjuryAnnual,
      incomeLimitWarning: pct >= 0.8,
      incomeLimitPercent: pct,
      incomeLimitMessage: _limitMsg(annualIncome, limit, 'АУСН'),
    );
  }

  // ── ОСНО: прогрессивный НДФЛ 13–22% + НДС 22% маржинально ─
  static TaxResult _osno(
    double periodIncome,
    double annualIncome,
    TaxSettings settings,
    int undefinedCount,
    int year,
  ) {
    final annualTax = _ndfl(annualIncome);
    final prevTax = _ndfl(math.max(0.0, annualIncome - periodIncome));
    final gross = annualTax - prevTax;
    final ins = _monthlyIns(annualIncome, settings, year);
    final annIns = _annualIns(annualIncome, settings, year);

    // НДС считается маржинально по периоду и НЕ агрегируется с НДФЛ —
    // отдельное поле vatTax, netTax остаётся только НДФЛ. Если в периоде
    // есть неразмеченные операции — автоматический расчёт НДС блокируется
    // (vatTax = 0) до ручного подтверждения пользователем.
    final vat = undefinedCount > 0 ? 0.0 : periodIncome * 0.22;

    return TaxResult(
      grossTax: gross,
      netTax: gross,
      monthlyInsurance: ins,
      annualInsurance: annIns,
      vatTax: vat,
    );
  }

  // ── ПСН: фиксированный патент ────────────────────────────
  static TaxResult _psn(
    double annualIncome,
    TaxSettings settings,
    int year,
    int periodMonths,
  ) {
    final monthly = settings.patentAnnualCost / 12;
    // Стоимость патента фиксирована и НЕ зависит от operations периода —
    // periodTransactions здесь ни при чём, поэтому сумму за квартал/год
    // нужно явно домножить на periodMonths (иначе "Налог за год" на ПСН
    // молча остался бы равен месячной стоимости патента).
    final periodCost = monthly * periodMonths;
    // Доп. 1%-взнос на ПСН считается не от реального дохода, а от
    // потенциально возможного дохода, зашитого в стоимость патента
    // (patentAnnualCost = 6% от потенциального дохода) — реальный
    // оборот на расчётный счёт налоговую для этой части не интересует.
    final potentialIncome = settings.patentAnnualCost > 0
        ? settings.patentAnnualCost / 0.06
        : 0.0;
    final ins = _monthlyIns(potentialIncome, settings, year);
    final annIns = _annualIns(potentialIncome, settings, year);
    final periodIns = ins * periodMonths;
    final maxDeduct = settings.hasEmployees ? periodCost * 0.5 : periodCost;
    final deduct = math.min(maxDeduct, periodIns);
    final net = math.max(0.0, periodCost - deduct);
    // Лимит РЕАЛЬНОГО дохода (для права на ПСН, в т.ч. совместно с УСН)
    // поэтапно снижается: 20 млн ₽ в 2026, 15 млн в 2027, 10 млн с 2028.
    final limit = _psnLimitForYear(year);
    final pct = annualIncome / limit;
    return TaxResult(
      grossTax: periodCost,
      insuranceDeduction: deduct,
      netTax: net,
      monthlyInsurance: ins,
      annualInsurance: annIns,
      incomeLimitWarning: pct >= 0.8,
      incomeLimitPercent: pct,
      incomeLimitMessage: _limitMsg(annualIncome, limit, 'ПСН'),
    );
  }

  static double _psnLimitForYear(int year) {
    if (year <= 2026) return 20_000_000.0;
    if (year == 2027) return 15_000_000.0;
    return 10_000_000.0; // 2028 и далее
  }

  // ── ЕСХН: 6% от (доходы − расходы) ──────────────────────
  static TaxResult _eshn(
    double income,
    double expenses,
    double annualIncome,
    TaxSettings settings,
    int year,
  ) {
    final rate = settings.eshnRate / 100;
    final base = math.max(0.0, income - expenses);
    final gross = base * rate;
    final ins = _monthlyIns(annualIncome, settings, year);
    final annIns = _annualIns(annualIncome, settings, year);
    // Плательщики ЕСХН обязаны платить НДС, если не воспользовались
    // освобождением по лимиту выручки (ст. 145 НК РФ) — порог 60 млн ₽
    // в год. Считается маржинально по периоду (та же схема, что у
    // ОСНО/УСН). Ставка 10% — основная для большинства сельхозпродукции;
    // 22% (реформа 2026) применяется только к прочим операциям
    // (например, сдача в аренду техники, не используемой в с/х напрямую) —
    // приложение не различает такие операции, поэтому применяет 10% как
    // основную ставку.
    final vat = _eshnVatForPeriod(income, annualIncome);
    final pct = annualIncome / _eshnVatThreshold;
    return TaxResult(
      grossTax: gross,
      netTax: gross,
      monthlyInsurance: ins,
      annualInsurance: annIns,
      vatApplicable: annualIncome > _eshnVatThreshold,
      vatTax: vat,
      incomeLimitWarning: pct >= 0.8,
      incomeLimitPercent: pct,
      incomeLimitMessage: annualIncome > _eshnVatThreshold
          ? 'Доход > 60 млн ₽ — утрачено освобождение от НДС (ст. 145 НК РФ)'
          : _limitMsg(annualIncome, _eshnVatThreshold, 'ЕСХН'),
    );
  }

  static const double _eshnVatThreshold = 60_000_000.0;

  static double _eshnVatCumulative(double annualIncome) =>
      math.max(0.0, annualIncome - _eshnVatThreshold) * 0.10;

  static double _eshnVatForPeriod(double periodIncome, double annualIncome) {
    final prevAnnualIncome = math.max(0.0, annualIncome - periodIncome);
    return _eshnVatCumulative(annualIncome) -
        _eshnVatCumulative(prevAnnualIncome);
  }

  // ── Страховые взносы ─────────────────────────────────────

  static double annualInsurance(
    double annualIncome, {
    TaxSettings settings = const TaxSettings(),
    int? year,
  }) => _annualIns(annualIncome, settings, year ?? DateTime.now().year);

  static double _annualIns(
    double annualIncome,
    TaxSettings settings,
    int year,
  ) {
    // Дополнительный 1%-взнос считается от полного годового дохода и НЕ
    // пропорционируется по дате регистрации — порог 300 000 ₽ и потолок
    // 321 818 ₽ фиксированы вне зависимости от числа отработанных месяцев.
    final additional = math.min(
      math.max(0.0, annualIncome - _insuranceThreshold) *
          _insuranceAdditionalRate,
      _insuranceAdditionalMax,
    );
    final fixed = _proratedFixedInsurance(year, settings.registrationDate);
    return fixed + additional;
  }

  static double _monthlyIns(
    double annualIncome,
    TaxSettings settings,
    int year,
  ) => _annualIns(annualIncome, settings, year) / 12;

  // Пропорциональный расчёт фиксированного взноса за неполный год по
  // формуле ФНС: Рас СВ ФР = (ФР/12) * М + (ФР/12 / Кн) * Дн, где
  // М — число полных месяцев деятельности, Кн — число дней в месяце
  // регистрации, Дн — число дней деятельности в этом месяце.
  static double _proratedFixedInsurance(int year, DateTime? registrationDate) {
    if (registrationDate == null || registrationDate.year < year) {
      return _insuranceFixed;
    }
    if (registrationDate.year > year) {
      return 0.0;
    }
    final month = registrationDate.month;
    final day = registrationDate.day;
    final daysInMonth = DateTime(year, month + 1, 0).day; // Кн
    final fullMonths = 12 - month; // М: месяцы ПОСЛЕ месяца регистрации
    final daysActive = daysInMonth - day + 1; // Дн: дни в месяце регистрации
    final perMonth = _insuranceFixed / 12;
    return perMonth * fullMonths + (perMonth / daysInMonth) * daysActive;
  }

  // ── Прогрессивный НДФЛ 2026 ──────────────────────────────
  // Пятиступенчатая шкала действует с 2025 года (ст. 224 НК РФ):
  // 13% / 15% / 18% / 20% / 22% с порогами 2,4 / 5 / 20 / 50 млн ₽.

  static double _ndfl(double income) {
    if (income <= 0) return 0;
    if (income <= 2_400_000) return income * 0.13;
    if (income <= 5_000_000) return 312_000 + (income - 2_400_000) * 0.15;
    if (income <= 20_000_000) return 702_000 + (income - 5_000_000) * 0.18;
    if (income <= 50_000_000) {
      return 3_402_000 + (income - 20_000_000) * 0.20;
    }
    return 9_402_000 + (income - 50_000_000) * 0.22;
  }

  // Ставка и границы диапазона прогрессивной шкалы НДФЛ, применимого к
  // указанному годовому доходу — для информационных надписей в UI.
  static ({double rate, double from, double? to}) ndflBracket(
    double annualIncome,
  ) {
    if (annualIncome <= 2_400_000) return (rate: 0.13, from: 0, to: 2_400_000);
    if (annualIncome <= 5_000_000) {
      return (rate: 0.15, from: 2_400_000, to: 5_000_000);
    }
    if (annualIncome <= 20_000_000) {
      return (rate: 0.18, from: 5_000_000, to: 20_000_000);
    }
    if (annualIncome <= 50_000_000) {
      return (rate: 0.20, from: 20_000_000, to: 50_000_000);
    }
    return (rate: 0.22, from: 50_000_000, to: null);
  }

  // ── Вспомогательные ─────────────────────────────────────

  static String? _limitMsg(double income, double limit, String modeName) {
    if (income >= limit) {
      return 'Превышен лимит $modeName ${_fmtAmount(limit)}';
    }
    if (income >= limit * 0.8) {
      return 'До лимита $modeName осталось ${_fmtAmount(limit - income)}';
    }
    return null;
  }

  static String _fmtAmount(double v) {
    if (v >= 1_000_000) return '${(v / 1_000_000).toStringAsFixed(1)} млн ₽';
    if (v >= 1_000) return '${(v / 1_000).toStringAsFixed(0)} тыс. ₽';
    return '${v.toStringAsFixed(0)} ₽';
  }

  static double _income(List<Transaction> txs) =>
      txs.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

  static double _expenses(List<Transaction> txs) => txs
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  static double _fromIndividuals(List<Transaction> txs) => txs
      .where((t) => t.type == TransactionType.incomeIndividual)
      .fold(0.0, (s, t) => s + t.amount);

  // Только явно подтверждённые юрлица/ИП
  static double _fromLegal(List<Transaction> txs) => txs
      .where((t) => t.type == TransactionType.incomeLegal)
      .fold(0.0, (s, t) => s + t.amount);

  // Неклассифицированный доход (generic income) — облагается как ФЛ
  static double _fromUnclassified(List<Transaction> txs) => txs
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);

  // ── Упрощённый расчёт для истории (без annualIncome) ────
  static double _simpleTax(
    List<Transaction> txs,
    TaxMode mode, {
    TaxSettings? settings,
  }) {
    // ПСН — фиксированная ежемесячная стоимость патента (годовая ставка ÷
    // 12), не зависит от дохода в конкретном периоде (в отличие от
    // остальных режимов ниже) — раньше здесь молча возвращался 0, из-за
    // чего "Налог" за любой месяц на патенте всегда показывал 0 ₽.
    if (mode == TaxMode.psn) {
      final monthly = (settings?.patentAnnualCost ?? 0) / 12;
      return double.parse(monthly.toStringAsFixed(2));
    }
    double tax = 0;
    for (final tx in txs) {
      if (!tx.isIncome) continue;
      switch (mode) {
        case TaxMode.npd:
          tax +=
              tx.amount *
              (tx.type == TransactionType.incomeLegal ? 0.06 : 0.04);
        case TaxMode.usn6:
          tax += tx.amount * 0.06;
        case TaxMode.usn15:
          tax += tx.amount * 0.15;
        case TaxMode.ausn8:
          tax += tx.amount * 0.08;
        case TaxMode.ausn20:
          tax += tx.amount * 0.20;
        case TaxMode.osno:
          tax += tx.amount * 0.13;
        case TaxMode.psn:
          break; // недостижимо — обработано выше, до цикла
        case TaxMode.eshn:
          tax += tx.amount * 0.06;
      }
    }
    return double.parse(tax.toStringAsFixed(2));
  }

  // ── Совместимый метод для старых вызовов ─────────────────
  static double calculateTax(
    List<Transaction> transactions,
    TaxMode mode, {
    TaxSettings? settings,
  }) => _simpleTax(transactions, mode, settings: settings);

  // ── Группировка по периодам для экрана истории ───────────
  static List<TaxPeriod> groupByPeriods(
    List<Transaction> transactions,
    TaxMode mode,
    TaxSettings settings,
  ) {
    final Map<String, List<Transaction>> grouped = {};
    for (final tx in transactions) {
      final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    // Доход по месяцам, сгруппированный по году — нужен для накопительного
    // (year-to-date) итога, от которого считается дополнительный 1%-взнос.
    // Без этого порог 300 000 ₽ сравнивался бы с доходом ОДНОГО месяца, а
    // не с накопленным годовым, и взнос занижался бы при неровном доходе.
    final incomeByYearMonth = <int, Map<int, double>>{};
    grouped.forEach((key, txs) {
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      incomeByYearMonth.putIfAbsent(year, () => {})[month] = _income(txs);
    });

    final periods = grouped.entries.map((entry) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final txs = entry.value;
      final income = _income(txs);
      final expenses = _expenses(txs);
      final tax = _simpleTax(txs, mode, settings: settings);
      final ytdIncome = incomeByYearMonth[year]!.entries
          .where((e) => e.key <= month)
          .fold(0.0, (s, e) => s + e.value);
      final insurance = mode.hasInsurance
          ? _monthlyIns(ytdIncome, settings, year)
          : 0.0;
      return TaxPeriod(
        year: year,
        month: month,
        income: income,
        expenses: expenses,
        tax: tax,
        insurance: insurance,
        transactionCount: txs.length,
      );
    }).toList();

    periods.sort(
      (a, b) => DateTime(b.year, b.month).compareTo(DateTime(a.year, a.month)),
    );
    return periods;
  }
}
