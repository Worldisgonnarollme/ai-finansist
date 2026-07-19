/// Типизированный вход для OPA, зеркалирующий канонический
/// opa/tax_policy_input.schema.json — без `Map<String,dynamic>` в публичном
/// API. Поля, не относящиеся к выбранному tax_mode, остаются null и не
/// попадают в JSON (additionalProperties: false в схеме не прощает лишних
/// ключей).
class OpaUser {
  final String taxMode;
  final bool? isIp;
  final String? region;

  const OpaUser({required this.taxMode, this.isIp, this.region});

  Map<String, dynamic> toJson() => {
    'tax_mode': taxMode,
    if (isIp != null) 'is_ip': isIp,
    if (region != null) 'region': region,
  };
}

class OpaTransaction {
  final String id;
  final String direction;
  final double amount;
  final String date;
  // Намеренно nullable, хотя схема требует их безусловно (related_to_business/
  // linked_document/has_vat_invoice/counterparty_type) или условно (остальные):
  // эта модель отражает то, что мы РЕАЛЬНО знаем о транзакции сейчас, а не
  // фабрикует значения, чтобы удовлетворить схему. Если поле null —
  // TaxPolicyInputValidator отклонит вход до отправки в OPA (см. OpaClient),
  // и это будет честно залогировано как "недостаточно данных", а не как
  // решение OPA.
  final String? counterpartyType;
  final bool? relatedToBusiness;
  final bool? linkedDocument;
  final bool? hasVatInvoice;
  final bool? vatApplicable;
  final bool? excludedUnderArt270;
  final String? vatException;
  final String? confirmedBy;
  final bool? isOwnProduction;
  final bool? includedUnderArt346_5;
  final bool? activityCoveredByPatent;

  const OpaTransaction({
    required this.id,
    required this.direction,
    required this.amount,
    required this.date,
    this.counterpartyType,
    this.relatedToBusiness,
    this.linkedDocument,
    this.hasVatInvoice,
    this.vatApplicable,
    this.excludedUnderArt270,
    this.vatException,
    this.confirmedBy,
    this.isOwnProduction,
    this.includedUnderArt346_5,
    this.activityCoveredByPatent,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'direction': direction,
    'amount': amount,
    'date': date,
    if (counterpartyType != null) 'counterparty_type': counterpartyType,
    if (relatedToBusiness != null) 'related_to_business': relatedToBusiness,
    if (linkedDocument != null) 'linked_document': linkedDocument,
    if (hasVatInvoice != null) 'has_vat_invoice': hasVatInvoice,
    if (vatApplicable != null) 'vat_applicable': vatApplicable,
    if (excludedUnderArt270 != null)
      'excluded_under_art_270': excludedUnderArt270,
    if (vatException != null) 'vat_exception': vatException,
    if (confirmedBy != null) 'confirmed_by': confirmedBy,
    if (isOwnProduction != null) 'is_own_production': isOwnProduction,
    if (includedUnderArt346_5 != null)
      'included_under_art_346_5': includedUnderArt346_5,
    if (activityCoveredByPatent != null)
      'activity_covered_by_patent': activityCoveredByPatent,
  };
}

class OpaAusnContext {
  final bool pilotRegionConfirmed;
  final double annualIncome;
  final int avgHeadcount;
  final double residualFixedAssetsValue;
  final bool hasBranches;
  final bool excludedActivity;

  const OpaAusnContext({
    required this.pilotRegionConfirmed,
    required this.annualIncome,
    required this.avgHeadcount,
    required this.residualFixedAssetsValue,
    required this.hasBranches,
    required this.excludedActivity,
  });

  Map<String, dynamic> toJson() => {
    'pilot_region_confirmed': pilotRegionConfirmed,
    'annual_income': annualIncome,
    'avg_headcount': avgHeadcount,
    'residual_fixed_assets_value': residualFixedAssetsValue,
    'has_branches': hasBranches,
    'excluded_activity': excludedActivity,
  };
}

class OpaEshnContext {
  final double agriIncomeShare;
  final bool? vatExemptionClaimed;
  final double? priorYearIncomeExclVat;

  const OpaEshnContext({
    required this.agriIncomeShare,
    this.vatExemptionClaimed,
    this.priorYearIncomeExclVat,
  });

  Map<String, dynamic> toJson() => {
    'agri_income_share': agriIncomeShare,
    if (vatExemptionClaimed != null)
      'vat_exemption_claimed': vatExemptionClaimed,
    if (priorYearIncomeExclVat != null)
      'prior_year_income_excl_vat': priorYearIncomeExclVat,
  };
}

class OpaPsnContext {
  final bool regionalActivityAllowed;
  final double annualIncomeAllPatents;
  final int avgHeadcountAllPatents;
  final bool hallAreaApplicable;
  final double? hallArea;

  const OpaPsnContext({
    required this.regionalActivityAllowed,
    required this.annualIncomeAllPatents,
    required this.avgHeadcountAllPatents,
    required this.hallAreaApplicable,
    this.hallArea,
  });

  Map<String, dynamic> toJson() => {
    'regional_activity_allowed': regionalActivityAllowed,
    'annual_income_all_patents': annualIncomeAllPatents,
    'avg_headcount_all_patents': avgHeadcountAllPatents,
    'hall_area_applicable': hallAreaApplicable,
    if (hallArea != null) 'hall_area': hallArea,
  };
}

class OpaNpdContext {
  final double annualIncome;
  final bool hasEmployees;
  final bool isResale;
  final bool sellsExcisableOrMarkedGoods;
  final bool minesOrSellsMinerals;
  final bool agentSchemeWithoutException;
  final bool combinesWithOtherRegimeSameActivity;

  const OpaNpdContext({
    required this.annualIncome,
    required this.hasEmployees,
    required this.isResale,
    required this.sellsExcisableOrMarkedGoods,
    required this.minesOrSellsMinerals,
    required this.agentSchemeWithoutException,
    required this.combinesWithOtherRegimeSameActivity,
  });

  Map<String, dynamic> toJson() => {
    'annual_income': annualIncome,
    'has_employees': hasEmployees,
    'is_resale': isResale,
    'sells_excisable_or_marked_goods': sellsExcisableOrMarkedGoods,
    'mines_or_sells_minerals': minesOrSellsMinerals,
    'agent_scheme_without_exception': agentSchemeWithoutException,
    'combines_with_other_regime_same_activity':
        combinesWithOtherRegimeSameActivity,
  };
}

class OpaContext {
  final OpaAusnContext? ausn;
  final OpaEshnContext? eshn;
  final OpaPsnContext? psn;
  final OpaNpdContext? npd;

  const OpaContext({this.ausn, this.eshn, this.psn, this.npd});

  bool get isEmpty =>
      ausn == null && eshn == null && psn == null && npd == null;

  Map<String, dynamic> toJson() => {
    if (ausn != null) 'ausn': ausn!.toJson(),
    if (eshn != null) 'eshn': eshn!.toJson(),
    if (psn != null) 'psn': psn!.toJson(),
    if (npd != null) 'npd': npd!.toJson(),
  };
}

/// Полный вход для data.tax.decision — мирроррит tax_policy_input.schema.json
/// 1:1. Всегда проверяй через TaxPolicyInputValidator до отправки в OPA: эта
/// модель не повторяет логику схемы (required/if-then), только структуру.
class OpaTaxPolicyInput {
  final OpaUser user;
  final OpaTransaction transaction;
  final OpaContext? context;

  const OpaTaxPolicyInput({
    required this.user,
    required this.transaction,
    this.context,
  });

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'transaction': transaction.toJson(),
    if (context != null && !context!.isEmpty) 'context': context!.toJson(),
  };
}
