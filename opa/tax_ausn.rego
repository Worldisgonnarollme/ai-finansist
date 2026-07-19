package tax.ausn

import rego.v1

############################################
# ЮРИДИЧЕСКАЯ ГРАНИЦА ОТВЕТСТВЕННОСТИ
#
# Этот пакет ВАЛИДИРУЕТ допустимость состояния (имеем ли мы право считать
# операцию/субъекта подпадающим под АУСН), но НЕ СЧИТАЕТ налог и НЕ
# ПОДБИРАЕТ процент (8%/20% — конкретные суммы вне scope policy). Расчёт —
# отдельный слой с отдельной ответственностью, вне OPA. Любая
# неопределённость трактуется как НЕсоответствие (compliant: false), а не
# как "требует ручной проверки" — для вопроса "имеем ли мы право
# применить режим" недостаточность данных юридически равна отсутствию
# права. Запрещены умножение суммы операции на процент и любые числовые
# налоговые поля (кроме пороговых значений лимитов, фиксированных
# законом — это не расчёт налога, а проверка допустимости состояния).
# Соблюдение проверяется CI-гардом (.github/workflows/policy-no-calc.yml).
############################################

ausn_modes := {"AUSN_INCOME", "AUSN_INCOME_EXPENSE"}

############################################
# ELIGIBILITY — ПРАВО ПРИМЕНЯТЬ РЕЖИМ
#
# Основание: Федеральный закон от 25.02.2022 № 17-ФЗ "О проведении
# эксперимента по установлению специального налогового режима
# «Автоматизированная упрощённая система налогообложения»".
############################################

default eligibility := {
  "compliant": false,
  "reason": "Нет достаточных оснований подтвердить право на применение АУСН",
  "legal_basis": [],
}

eligibility := {
  "compliant": true,
  "reason": "Подтверждены пилотный регион, лимиты дохода/численности/ОС, отсутствие филиалов и запрещённых видов деятельности",
  "legal_basis": ["Федеральный закон от 25.02.2022 № 17-ФЗ"],
} if {
  input.user.tax_mode in ausn_modes
  input.context.ausn.pilot_region_confirmed == true
  input.context.ausn.annual_income <= 60000000
  input.context.ausn.avg_headcount <= 5
  input.context.ausn.residual_fixed_assets_value <= 150000000
  input.context.ausn.has_branches == false
  input.context.ausn.excluded_activity == false
}

############################################
# INCOME — ПРИЗНАНИЕ ДОХОДА
#
# Доход на АУСН подтверждается не первичными документами, а данными
# уполномоченного банка/ККТ — это структурное условие закона № 17-ФЗ, а
# не эвристика.
############################################

default income := {
  "compliant": false,
  "reason": "Доход не подтверждён уполномоченным банком или ККТ",
  "legal_basis": [],
}

income := {
  "compliant": true,
  "reason": "Доход подтверждён данными уполномоченного банка или ККТ",
  "legal_basis": ["Федеральный закон от 25.02.2022 № 17-ФЗ"],
} if {
  input.user.tax_mode in ausn_modes
  input.transaction.direction == "income"
  input.transaction.confirmed_by in {"authorized_bank", "kkt"}
}

############################################
# EXPENSE — РАСХОД (ТОЛЬКО ОБЪЕКТ «ДОХОДЫ МИНУС РАСХОДЫ»)
############################################

default expense := {
  "compliant": false,
  "reason": "Расход не подтверждён уполномоченным банком",
  "legal_basis": [],
}

expense := {
  "compliant": true,
  "reason": "Расход подтверждён данными уполномоченного банка",
  "legal_basis": ["Федеральный закон от 25.02.2022 № 17-ФЗ"],
} if {
  input.user.tax_mode == "AUSN_INCOME_EXPENSE"
  input.transaction.direction == "expense"
  input.transaction.confirmed_by == "authorized_bank"
}

# Объект «доходы» не предусматривает расходы как налоговую категорию —
# любая попытка заявить расход для AUSN_INCOME структурно недопустима
# независимо от подтверждения.
expense := {
  "compliant": false,
  "reason": "Для объекта «доходы» АУСН расходы не являются налоговой категорией",
  "legal_basis": ["Федеральный закон от 25.02.2022 № 17-ФЗ"],
} if {
  input.user.tax_mode == "AUSN_INCOME"
  input.transaction.direction == "expense"
}

############################################
# VAT — НДС НЕ ПРИМЕНЯЕТСЯ К ДЕЯТЕЛЬНОСТИ НА АУСН
#
# В отличие от eligibility/income/expense, default-состояние здесь —
# подтверждённое отсутствие НДС (это нормальное состояние режима, а не
# неопределённость). Нарушение — явный признак vat_applicable без
# исключения.
############################################

has_valid_vat_exception if {
  input.transaction.vat_exception in {"import_vat", "tax_agent_vat"}
}

default vat := {
  "compliant": true,
  "reason": "НДС не применяется к деятельности на АУСН",
  "legal_basis": ["Федеральный закон от 25.02.2022 № 17-ФЗ"],
}

vat := {
  "compliant": true,
  "reason": "Ввозной НДС или НДС налогового агента — отдельная обязанность, не связанная с объектом налогообложения АУСН",
  "legal_basis": ["НК РФ ст. 161"],
} if {
  input.transaction.vat_applicable == true
  has_valid_vat_exception
}

vat := {
  "compliant": false,
  "reason": "НДС заявлен для деятельности на АУСН без основания (импорт/налоговый агент) — несовместимо с объектом налогообложения режима",
  "legal_basis": ["Федеральный закон от 25.02.2022 № 17-ФЗ"],
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
  "vat": vat,
  "compliant": true,
} if {
  input.transaction.direction == "expense"
  eligibility.compliant == true
  expense.compliant == true
  vat.compliant == true
}
