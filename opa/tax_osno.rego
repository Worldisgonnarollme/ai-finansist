package tax.osno

import rego.v1

############################################
# ЮРИДИЧЕСКАЯ ГРАНИЦА ОТВЕТСТВЕННОСТИ
#
# Этот агрегатор объединяет КВАЛИФИКАЦИОННЫЕ решения трёх под-пакетов
# (income_tax/vat/expenses), но сам не считает и не подбирает процент
# налога — здесь не должно быть никаких числовых налоговых полей или
# умножения суммы операции на процент. Расчёт суммы налога — отдельный
# слой с отдельной ответственностью, вне OPA. Соблюдение проверяется
# CI-гардом (.github/workflows/opa-osno-guard.yml).
############################################

############################################
# AGGREGATED DECISION
#
# Решение разделено по input.transaction.direction: income_tax и vat
# относятся только к доходным операциям, expense — только к расходным.
# Раньше единое правило требовало одновременной уверенности по всем трём
# под-пакетам, а income_tax/expenses структурно взаимоисключающие
# (требуют противоположных direction) — поэтому decision НИКОГДА не мог
# разрешиться в needs_review == false. Default ниже не fabricates
# поля под-пакетов, которые не относятся к direction операции — он
# только сигнализирует needs_review, не выдавая чужой результат за
# реальный (см. ADR-0002).
############################################

default decision := {
  "needs_review": true
}

decision := {
  "income_tax": income_tax,
  "vat": vat,
  "needs_review": false
} if {
  input.transaction.direction == "income"

  income_tax := data.tax.osno.income_tax.result
  vat := data.tax.osno.vat.result

  income_tax.needs_review == false
  vat.needs_review == false
}

decision := {
  "expense": expense,
  "needs_review": false
} if {
  input.transaction.direction == "expense"

  expense := data.tax.osno.expenses.result

  expense.needs_review == false
}
