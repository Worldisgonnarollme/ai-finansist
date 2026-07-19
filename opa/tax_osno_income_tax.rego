package tax.osno.income_tax

import rego.v1

############################################
# ЮРИДИЧЕСКАЯ ГРАНИЦА ОТВЕТСТВЕННОСТИ
#
# Этот пакет КВАЛИФИЦИРУЕТ доход (является ли он объектом налогообложения
# по ОСНО), но НЕ СЧИТАЕТ налог и НЕ ПОДБИРАЕТ процент (13/15/20% и т.п.).
# Расчёт суммы налога — отдельный слой с отдельной ответственностью, вне
# OPA. Запрещены умножение суммы операции на процент и любые числовые
# налоговые поля. Соблюдение проверяется CI-гардом
# (.github/workflows/opa-osno-guard.yml).
############################################

############################################
# ANTI-HALLUCINATION DEFAULT
############################################

default result := {
  "is_taxable_income": false,
  "needs_review": true,
  "reason": "Нет достаточных оснований для признания дохода по ОСНО",
  "legal_basis": []
}

############################################
# BUSINESS INCOME — ИП (НДФЛ)
############################################

result := {
  "is_taxable_income": true,
  "needs_review": false,
  "reason": "Доход ИП от предпринимательской деятельности включается в налоговую базу по НДФЛ (ОСНО)",
  "legal_basis": [
    "НК РФ ст. 210"
  ]
} if {
  input.user.tax_mode == "OSNO"
  input.user.is_ip == true
  input.transaction.direction == "income"
  input.transaction.related_to_business == true
}

############################################
# BUSINESS INCOME — ОРГАНИЗАЦИЯ (НАЛОГ НА ПРИБЫЛЬ)
############################################

result := {
  "is_taxable_income": true,
  "needs_review": false,
  "reason": "Доход организации от предпринимательской деятельности включается в налоговую базу по налогу на прибыль (ОСНО)",
  "legal_basis": [
    "НК РФ ст. 247"
  ]
} if {
  input.user.tax_mode == "OSNO"
  input.user.is_ip == false
  input.transaction.direction == "income"
  input.transaction.related_to_business == true
}
