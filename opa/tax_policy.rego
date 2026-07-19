package tax.policy

import rego.v1

##################################################
# ANTI-HALLUCINATION DEFAULT
# Если ни одно правило не применилось —
# операция уходит на ручную проверку
##################################################

# Основание: ст. 41 НК РФ — доходом признаётся экономическая выгода;
# без структурных данных, подтверждающих связь операции с
# предпринимательской/профессиональной деятельностью, факт экономической
# выгоды от такой деятельности не установлен.
default result := {
  "category": "unknown",
  "taxable": false,
  "tax_rate": null,
  "deductible": false,
  "needs_review": true,
  "reason": "Ст. 41 НК РФ: недостаточно структурных данных, чтобы установить экономическую выгоду от предпринимательской деятельности — требуется подтверждение пользователя"
}

##################################################
# HELPERS
##################################################

is_income if {
  input.transaction.direction == "income"
}

is_expense if {
  input.transaction.direction == "expense"
}

is_individual if {
  input.transaction.counterparty_type == "individual"
}

is_company_or_platform if {
  input.transaction.counterparty_type == "company"
} else if {
  input.transaction.counterparty_type == "platform"
}

has_business_description if {
  contains(lower(input.transaction.description), "договор")
} else if {
  contains(lower(input.transaction.description), "оплата")
} else if {
  contains(lower(input.transaction.description), "услуги")
}

# Перевод от физлица без признаков бизнеса. Отдельный helper — нужен и в
# правиле personal_transfer, и как исключающее условие в правилах режимов
# (USN/AUSN), чтобы их тела не пересекались: иначе при is_individual и
# not has_business_description одновременно истинны и personal_transfer,
# и правило режима — "complete rules must not produce multiple outputs".
#
# linked_document (договор/акт/счёт) — структурный факт, а не текстовая
# эвристика: его наличие исключает personal_transfer независимо от того,
# что написано в описании платежа.
is_personal_transfer if {
  is_income
  is_individual
  not has_business_description
  not input.transaction.linked_document == true
}

##################################################
# PERSONAL TRANSFERS
# Переводы между физлицами без признаков бизнеса
##################################################

# Основание: ст. 41 НК РФ — объект налогообложения — экономическая выгода
# от деятельности, а не любое поступление денег. needs_review: true,
# потому что отсутствие слов "договор/оплата/услуги" в описании — это
# слабый отрицательный признак (не подтверждает личный характер платежа,
# лишь не подтверждает бизнес-характер). Окончательное решение принимает
# пользователь.
result := {
  "category": "personal_transfer",
  "taxable": false,
  "tax_rate": null,
  "deductible": false,
  "needs_review": true,
  "reason": "Ст. 41 НК РФ: перевод от физического лица без явных признаков предпринимательской деятельности — экономическая выгода от деятельности не подтверждена, требуется подтверждение пользователя"
} if {
  is_personal_transfer
}

##################################################
# NPD — Самозанятые
##################################################

# Основание: ст. 8 422-ФЗ "О проведении эксперимента по установлению
# специального налогового режима «Налог на профессиональный доход»" —
# ставка НПД зависит ИСКЛЮЧИТЕЛЬНО от типа контрагента (6% — юрлицо/ИП,
# 4% — физлицо). counterparty_type — структурное поле входа, не текстовая
# эвристика, поэтому здесь needs_review = false оправдан.
result := {
  "category": "business_income",
  "taxable": true,
  "tax_rate": 0.06,
  "deductible": false,
  "needs_review": false,
  "reason": "Доход от юридического лица или платформы по НПД, ст. 8 422-ФЗ (ставка 6%)"
} if {
  input.user.tax_mode == "NPD"
  is_income
  is_company_or_platform
}

# Основание: ст. 8 422-ФЗ, ставка 4% — доход от физлица. Подтверждён
# структурным фактом linked_document (договор/акт/счёт), а не текстом
# описания платежа — поэтому needs_review = false оправдан.
result := {
  "category": "business_income",
  "taxable": true,
  "tax_rate": 0.04,
  "deductible": false,
  "needs_review": false,
  "reason": "Доход от физического лица по НПД, подтверждён договором/актом/счётом, ст. 8 422-ФЗ (ставка 4%)"
} if {
  input.user.tax_mode == "NPD"
  is_income
  is_individual
  input.transaction.linked_document == true
}

# Признаки оплаты услуг ЕСТЬ только в тексте описания (без linked_document) —
# это текстовая эвристика, а не норма ФНС. Прямого основания для 422-ФЗ
# ст. 8 нет, поэтому taxable/tax_rate НЕ устанавливаются — только подсказка
# категории с обязательной проверкой пользователем.
result := {
  "category": "business_income",
  "taxable": false,
  "tax_rate": null,
  "deductible": false,
  "needs_review": true,
  "reason": "Возможный доход физлица по НПД (ст. 8 422-ФЗ, ставка 4%) — есть признак оплаты услуг в описании, но нет подтверждающего документа; основание не подтверждено структурными данными, требуется подтверждение пользователя"
} if {
  input.user.tax_mode == "NPD"
  is_income
  is_individual
  has_business_description
  not input.transaction.linked_document == true
}

##################################################
# USN 6% — ДОХОДЫ (кассовый метод)
##################################################

# Основание: п. 1 ст. 346.17 НК РФ — при УСН доходы признаются кассовым
# методом (на дату поступления денежных средств), независимо от текста
# описания платежа. is_personal_transfer исключён отдельно (см. helper) —
# структурный/эвристический фильтр для операций, не относящихся к
# предпринимательской деятельности (ст. 41 НК РФ).
result := {
  "category": "business_income",
  "taxable": true,
  "tax_rate": 0.06,
  "deductible": false,
  "needs_review": false,
  "reason": "П. 1 ст. 346.17 НК РФ: доход ИП на УСН «доходы» (6%), признан по кассовому методу"
} if {
  input.user.tax_mode == "USN_INCOME"
  is_income
  not is_personal_transfer
}

##################################################
# USN 15% — ДОХОДЫ МИНУС РАСХОДЫ
##################################################

# Основание: п. 1 ст. 346.17 НК РФ — кассовый метод признания доходов
# (аналогично УСН «доходы»).
result := {
  "category": "business_income",
  "taxable": true,
  "tax_rate": 0.15,
  "deductible": false,
  "needs_review": false,
  "reason": "П. 1 ст. 346.17 НК РФ: доход ИП на УСН «доходы минус расходы» (15%), признан по кассовому методу"
} if {
  input.user.tax_mode == "USN_INCOME_EXPENSE"
  is_income
  not is_personal_transfer
}

# Основание: ст. 346.16 НК РФ (закрытый перечень расходов УСН) + ст. 252
# НК РФ (расходы должны быть документально подтверждены). linked_document —
# структурный факт наличия договора/акта/счёта, поэтому needs_review=false
# оправдан только при его наличии; без документа — нет основания.
result := {
  "category": "business_expense",
  "taxable": false,
  "tax_rate": null,
  "deductible": true,
  "needs_review": false,
  "reason": "Ст. 346.16 и ст. 252 НК РФ: расход ИП на УСН 15%, документально подтверждён (договор/акт/счёт)"
} if {
  input.user.tax_mode == "USN_INCOME_EXPENSE"
  is_expense
  input.transaction.linked_document == true
}

# Расход без подтверждающего документа — ст. 252 НК РФ требует
# документального подтверждения для учёта расхода; без него основания для
# deductible=true нет.
result := {
  "category": "business_expense",
  "taxable": false,
  "tax_rate": null,
  "deductible": false,
  "needs_review": true,
  "reason": "Ст. 252 НК РФ: расход ИП на УСН 15% без документального подтверждения (нет договора/акта/счёта) — учёт как расхода требует подтверждения пользователя"
} if {
  input.user.tax_mode == "USN_INCOME_EXPENSE"
  is_expense
  not input.transaction.linked_document == true
}

##################################################
# AUSN — ПЕРЕНЕСЕНО В ОТДЕЛЬНОЕ ДЕРЕВО tax.ausn.*
#
# АУСН больше не квалифицируется здесь: режим юридически устроен иначе,
# чем "одно правило = один структурный факт" (НПД/УСН) — у него есть
# собственный вопрос допустимости состояния (лимиты/пилотный регион/
# подтверждение банком), не сводимый к простому taxable+tax_rate. См.
# docs/adr/0007-ausn-eshn-psn-eligibility-trees.md.
##################################################

##################################################
# SAFETY GUARD
# Запрещает авто-решения без юридического основания
##################################################

deny[msg] if {
  result.needs_review == false
  result.reason == ""
  msg := "Автоматическая классификация без юридического основания запрещена"
}