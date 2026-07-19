package tax.psn

import rego.v1

############################################
# ЮРИДИЧЕСКАЯ ГРАНИЦА ОТВЕТСТВЕННОСТИ
#
# Этот пакет ВАЛИДИРУЕТ допустимость состояния (имеем ли мы право считать
# операцию покрытой патентом), но НЕ СЧИТАЕТ стоимость патента и не имеет
# отношения к фактическому доходу — налоговая база ПСН (потенциально
# возможный доход) определяется вне OPA и вне этого вопроса вовсе. Любая
# неопределённость трактуется как НЕсоответствие (compliant: false), а не
# как "требует ручной проверки". Запрещены любые числовые налоговые поля
# (кроме пороговых значений лимитов, фиксированных законом). Соблюдение
# проверяется CI-гардом (.github/workflows/policy-no-calc.yml).
############################################

############################################
# ELIGIBILITY — ПРАВО НА ПАТЕНТ
#
# Основание: ст. 346.43 НК РФ (субъект — только ИП, лимит численности,
# площадь зала), ст. 346.45 НК РФ (совокупный лимит дохода 60 млн).
############################################

hall_area_ok if {
  input.context.psn.hall_area_applicable == false
}

hall_area_ok if {
  input.context.psn.hall_area_applicable == true
  input.context.psn.hall_area <= 150
}

default eligibility := {
  "compliant": false,
  "reason": "Нет достаточных оснований подтвердить право на применение ПСН",
  "legal_basis": [],
}

eligibility := {
  "compliant": true,
  "reason": "Подтверждены статус ИП, допустимый вид деятельности по региональному закону, лимиты дохода/численности и (если применимо) площади зала",
  "legal_basis": ["НК РФ ст. 346.43", "НК РФ ст. 346.45"],
} if {
  input.user.tax_mode == "PSN"
  input.user.is_ip == true
  input.context.psn.regional_activity_allowed == true
  input.context.psn.annual_income_all_patents <= 60000000
  input.context.psn.avg_headcount_all_patents <= 15
  hall_area_ok
}

############################################
# INCOME — ДОХОД ПОКРЫТ ДЕЙСТВУЮЩИМ ПАТЕНТОМ
############################################

default income := {
  "compliant": false,
  "reason": "Нет подтверждения, что доход относится к виду деятельности, покрытому действующим патентом",
  "legal_basis": [],
}

income := {
  "compliant": true,
  "reason": "Доход относится к виду деятельности, покрытому действующим патентом",
  "legal_basis": ["НК РФ ст. 346.43", "НК РФ ст. 346.45"],
} if {
  input.user.tax_mode == "PSN"
  input.transaction.direction == "income"
  input.transaction.activity_covered_by_patent == true
}

############################################
# EXPENSE — РАСХОДЫ НЕ ЯВЛЯЮТСЯ НАЛОГОВОЙ КАТЕГОРИЕЙ ПСН
#
# Налоговая база ПСН — потенциально возможный к получению годовой доход,
# она не зависит от фактических расходов. Это не неопределённость, а
# уверенный (needs_review-эквивалент: confident) ответ "нет" независимо
# от документального подтверждения расхода.
############################################

default expense := {
  "compliant": false,
  "reason": "Расходы не являются налоговой категорией для ПСН",
  "legal_basis": ["НК РФ ст. 346.47", "НК РФ ст. 346.48"],
}

expense := {
  "compliant": false,
  "reason": "Расходы не являются налоговой категорией для ПСН — налоговая база (потенциально возможный доход) от них не зависит",
  "legal_basis": ["НК РФ ст. 346.47", "НК РФ ст. 346.48"],
} if {
  input.user.tax_mode == "PSN"
  input.transaction.direction == "expense"
}

############################################
# VAT — ИП НА ПСН НЕ ПРИЗНАЁТСЯ ПЛАТЕЛЬЩИКОМ НДС ПО ПАТЕНТНОЙ ДЕЯТЕЛЬНОСТИ
############################################

has_valid_vat_exception if {
  input.transaction.vat_exception in {"import_vat", "tax_agent_vat"}
}

default vat := {
  "compliant": true,
  "reason": "ИП на ПСН не признаётся плательщиком НДС по операциям в рамках патентной деятельности",
  "legal_basis": ["НК РФ ст. 346.43 п. 11"],
}

vat := {
  "compliant": true,
  "reason": "Ввозной НДС или НДС налогового агента — отдельная обязанность, не связанная с патентной деятельностью",
  "legal_basis": ["НК РФ ст. 161"],
} if {
  input.transaction.vat_applicable == true
  has_valid_vat_exception
}

vat := {
  "compliant": false,
  "reason": "НДС заявлен для деятельности, покрытой патентом, без основания (импорт/налоговый агент) — несовместимо с п. 11 ст. 346.43 НК РФ",
  "legal_basis": ["НК РФ ст. 346.43 п. 11"],
} if {
  input.transaction.vat_applicable == true
  not has_valid_vat_exception
}

############################################
# AGGREGATED DECISION
############################################

default decision := {"compliant": false}

decision := {
  "eligibility": eligibility,
  "income": income,
  "vat": vat,
  "compliant": true,
} if {
  input.transaction.direction == "income"
  eligibility.compliant == true
  income.compliant == true
  vat.compliant == true
}

decision := {
  "eligibility": eligibility,
  "expense": expense,
  "compliant": false,
} if {
  input.user.tax_mode == "PSN"
  input.transaction.direction == "expense"
}
