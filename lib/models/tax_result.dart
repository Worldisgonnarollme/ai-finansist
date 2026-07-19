class TaxResult {
  final double grossTax;
  final double insuranceDeduction;
  final double netTax;
  final double monthlyInsurance;
  final double annualInsurance;
  final bool vatApplicable;
  // НДС за период (только ОСНО) — считается маржинально, НЕ агрегируется
  // с netTax (НДФЛ). 0, если есть неразмеченные операции (см. undefinedCount).
  final double vatTax;
  // НПД: НДФЛ на доход сверх лимита 2,4 млн ₽/год — считается маржинально
  // по периоду (аналогично vatTax), НЕ агрегируется с netTax (ставка НПД
  // 4%/6% на сумму сверх лимита не начисляется — доход выходит из-под
  // действия спецрежима, физлицо платит НДФЛ по прогрессивной шкале).
  final double ndflOverLimitTax;
  final bool incomeLimitWarning;
  final double? incomeLimitPercent;
  final String? incomeLimitMessage;
  final bool employeeLimitWarning;
  final String? employeeLimitMessage;
  // НПД: сколько вычета использовано в этом периоде
  final double npdDeductionUsed;
  // НПД: остаток вычета после этого периода
  final double npdDeductionRemaining;
  // Кол-во операций периода с неопределённой классификацией (taxRelevance.undefined).
  // Такие операции НЕ участвуют в расчёте автоматически — pre-validation policy.
  final int undefinedCount;

  const TaxResult({
    required this.grossTax,
    this.insuranceDeduction = 0,
    required this.netTax,
    this.monthlyInsurance = 0,
    this.annualInsurance = 0,
    this.vatApplicable = false,
    this.vatTax = 0,
    this.ndflOverLimitTax = 0,
    this.incomeLimitWarning = false,
    this.incomeLimitPercent,
    this.incomeLimitMessage,
    this.employeeLimitWarning = false,
    this.employeeLimitMessage,
    this.npdDeductionUsed = 0,
    this.npdDeductionRemaining = 0,
    this.undefinedCount = 0,
  });

  double get totalMonthly => netTax + monthlyInsurance;
  bool get hasUndefinedTransactions => undefinedCount > 0;
  String get undefinedMessage => undefinedCount == 1
      ? 'Есть 1 неразмеченная операция — требуется проверка'
      : 'Есть $undefinedCount неразмеченных операций — требуется проверка';

  TaxResult withUndefinedCount(int count) => TaxResult(
    grossTax: grossTax,
    insuranceDeduction: insuranceDeduction,
    netTax: netTax,
    monthlyInsurance: monthlyInsurance,
    annualInsurance: annualInsurance,
    vatApplicable: vatApplicable,
    vatTax: vatTax,
    ndflOverLimitTax: ndflOverLimitTax,
    incomeLimitWarning: incomeLimitWarning,
    incomeLimitPercent: incomeLimitPercent,
    incomeLimitMessage: incomeLimitMessage,
    employeeLimitWarning: employeeLimitWarning,
    employeeLimitMessage: employeeLimitMessage,
    npdDeductionUsed: npdDeductionUsed,
    npdDeductionRemaining: npdDeductionRemaining,
    undefinedCount: count,
  );

  TaxResult withEmployeeLimit({
    required bool warning,
    required String? message,
  }) => TaxResult(
    grossTax: grossTax,
    insuranceDeduction: insuranceDeduction,
    netTax: netTax,
    monthlyInsurance: monthlyInsurance,
    annualInsurance: annualInsurance,
    vatApplicable: vatApplicable,
    vatTax: vatTax,
    ndflOverLimitTax: ndflOverLimitTax,
    incomeLimitWarning: incomeLimitWarning,
    incomeLimitPercent: incomeLimitPercent,
    incomeLimitMessage: incomeLimitMessage,
    employeeLimitWarning: warning,
    employeeLimitMessage: message,
    npdDeductionUsed: npdDeductionUsed,
    npdDeductionRemaining: npdDeductionRemaining,
    undefinedCount: undefinedCount,
  );
}
