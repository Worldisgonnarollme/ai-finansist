package tax.policy

import rego.v1

# ==================================================
# DEFAULT / ANTI-HALLUCINATION
# ==================================================

# Позиция ФНС: ст. 41 НК РФ — доход = экономическая выгода. Если ни один
# режим/правило не покрывает комбинацию входных данных, экономическая
# выгода от предпринимательской деятельности структурно не подтверждена —
# операция уходит на ручную проверку, а не в налоговую базу.
#
# tax_mode здесь заведомо синтетический (не из реального enum) — ОСНО,
# АУСН, ЕСХН и ПСН больше не подходят для этого теста: у каждого теперь
# собственное дерево пакетов (tax.osno.*/tax.ausn.*/tax.eshn.*/tax.psn.*),
# и они не должны демонстрировать generic fallback пакета tax.policy.
test_default_unknown_when_no_rule_matches if {
	test_input := {
		"user": {"tax_mode": "UNHANDLED_MODE"},
		"transaction": {
			"id": "t-default",
			"direction": "income",
			"amount": 1000,
			"date": "2026-06-01",
			"counterparty_type": "bank",
			"description": "",
		},
	}

	result == {
		"category": "unknown",
		"taxable": false,
		"tax_rate": null,
		"deductible": false,
		"needs_review": true,
		"reason": "Ст. 41 НК РФ: недостаточно структурных данных, чтобы установить экономическую выгоду от предпринимательской деятельности — требуется подтверждение пользователя",
	} with input as test_input
}

# ==================================================
# PERSONAL TRANSFERS
# ==================================================

# Позиция ФНС: ст. 41 НК РФ — облагается только экономическая выгода от
# деятельности. Перевод от физлица без слов "договор/оплата/услуги" и без
# подтверждающего документа — это слабый сигнал "вероятно личное", а не
# доказательство. needs_review=true: пользователь должен подтвердить, а не
# policy самостоятельно принимает решение.
test_personal_transfer_no_keywords_no_document if {
	test_input := {
		"user": {"tax_mode": "USN_INCOME"},
		"transaction": {
			"id": "t-personal",
			"direction": "income",
			"amount": 5000,
			"date": "2026-06-01",
			"counterparty_type": "individual",
			"description": "Спасибо!",
		},
	}

	result == {
		"category": "personal_transfer",
		"taxable": false,
		"tax_rate": null,
		"deductible": false,
		"needs_review": true,
		"reason": "Ст. 41 НК РФ: перевод от физического лица без явных признаков предпринимательской деятельности — экономическая выгода от деятельности не подтверждена, требуется подтверждение пользователя",
	} with input as test_input
}

# Регрессия на конфликт вычисления: тот же кейс (физлицо, нет ключевых
# слов) должен попадать ИМЕННО в personal_transfer, а не одновременно
# совпадать с правилом режима НПД/УСН/АУСН (что раньше приводило к
# "complete rules must not produce multiple outputs"). Если эта проверка
# падает с ошибкой eval, а не с несовпадением значения — значит, правила
# режимов снова пересекаются с personal_transfer.
test_personal_transfer_no_conflict_with_npd if {
	test_input := {
		"user": {"tax_mode": "NPD"},
		"transaction": {
			"id": "t-personal-npd",
			"direction": "income",
			"amount": 2000,
			"date": "2026-06-01",
			"counterparty_type": "individual",
			"description": "Привет, держи",
		},
	}

	result.category == "personal_transfer" with input as test_input
}

# Структурный факт linked_document (договор/акт/счёт) сильнее отсутствия
# ключевых слов в описании: наличие документа — прямое юридическое
# основание для отнесения к предпринимательской деятельности, поэтому
# personal_transfer здесь НЕ должен срабатывать (см. helper
# is_personal_transfer).
test_linked_document_overrides_missing_keywords if {
	test_input := {
		"user": {"tax_mode": "USN_INCOME"},
		"transaction": {
			"id": "t-doc-no-kw",
			"direction": "income",
			"amount": 15000,
			"date": "2026-06-01",
			"counterparty_type": "individual",
			"description": "Спасибо!",
			"linked_document": true,
		},
	}

	result.category == "business_income" with input as test_input
	result.tax_rate == 0.06 with input as test_input
	result.needs_review == false with input as test_input
}

# ==================================================
# NPD — Самозанятые (ст. 8 422-ФЗ)
# ==================================================

# Позиция ФНС: ст. 8 422-ФЗ — ставка НПД зависит от типа контрагента.
# Доход от юрлица/платформы — 6%. counterparty_type — структурное поле,
# поэтому needs_review=false оправдан без анализа текста описания.
test_npd_income_from_company_six_percent if {
	test_input := {
		"user": {"tax_mode": "NPD"},
		"transaction": {
			"id": "t-npd-company",
			"direction": "income",
			"amount": 50000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"description": "Оплата по договору",
		},
	}

	result == {
		"category": "business_income",
		"taxable": true,
		"tax_rate": 0.06,
		"deductible": false,
		"needs_review": false,
		"reason": "Доход от юридического лица или платформы по НПД, ст. 8 422-ФЗ (ставка 6%)",
	} with input as test_input
}

# Платформа (маркетплейс, агрегатор) приравнена к юрлицу для целей ставки
# НПД — также 6% по ст. 8 422-ФЗ.
test_npd_income_from_platform_six_percent if {
	test_input := {
		"user": {"tax_mode": "NPD"},
		"transaction": {
			"id": "t-npd-platform",
			"direction": "income",
			"amount": 3000,
			"date": "2026-06-01",
			"counterparty_type": "platform",
			"description": "Выплата с маркетплейса",
		},
	}

	result.tax_rate == 0.06 with input as test_input
	result.needs_review == false with input as test_input
}

# Позиция ФНС: ст. 8 422-ФЗ, ставка 4% для физлиц — подтверждена
# структурным фактом linked_document (договор/акт/счёт), а не текстом
# описания, поэтому needs_review=false оправдан.
test_npd_income_from_individual_with_document_four_percent if {
	test_input := {
		"user": {"tax_mode": "NPD"},
		"transaction": {
			"id": "t-npd-individual-doc",
			"direction": "income",
			"amount": 3000,
			"date": "2026-06-01",
			"counterparty_type": "individual",
			"description": "Оплата услуг по договору",
			"linked_document": true,
		},
	}

	result == {
		"category": "business_income",
		"taxable": true,
		"tax_rate": 0.04,
		"deductible": false,
		"needs_review": false,
		"reason": "Доход от физического лица по НПД, подтверждён договором/актом/счётом, ст. 8 422-ФЗ (ставка 4%)",
	} with input as test_input
}

# КРИТИЧЕСКОЕ ПРАВИЛО: текстовый признак "оплата услуг" в описании БЕЗ
# подтверждающего документа — это эвристика, не норма ФНС. Запрещено
# выставлять taxable=true/tax_rate без юридического основания — поэтому
# здесь должен остаться needs_review=true, taxable=false, tax_rate=null,
# даже несмотря на явный текстовый сигнал "по договору".
test_npd_income_from_individual_keywords_only_needs_review if {
	test_input := {
		"user": {"tax_mode": "NPD"},
		"transaction": {
			"id": "t-npd-individual-kw",
			"direction": "income",
			"amount": 3000,
			"date": "2026-06-01",
			"counterparty_type": "individual",
			"description": "Оплата услуг по договору",
		},
	}

	result == {
		"category": "business_income",
		"taxable": false,
		"tax_rate": null,
		"deductible": false,
		"needs_review": true,
		"reason": "Возможный доход физлица по НПД (ст. 8 422-ФЗ, ставка 4%) — есть признак оплаты услуг в описании, но нет подтверждающего документа; основание не подтверждено структурными данными, требуется подтверждение пользователя",
	} with input as test_input
}

# ==================================================
# USN 6% — ДОХОДЫ (п. 1 ст. 346.17 НК РФ — кассовый метод)
# ==================================================

test_usn_income_six_percent_company if {
	test_input := {
		"user": {"tax_mode": "USN_INCOME"},
		"transaction": {
			"id": "t-usn6",
			"direction": "income",
			"amount": 100000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"description": "Оплата по счёту",
		},
	}

	result == {
		"category": "business_income",
		"taxable": true,
		"tax_rate": 0.06,
		"deductible": false,
		"needs_review": false,
		"reason": "П. 1 ст. 346.17 НК РФ: доход ИП на УСН «доходы» (6%), признан по кассовому методу",
	} with input as test_input
}

# ==================================================
# USN 15% — ДОХОДЫ МИНУС РАСХОДЫ
# ==================================================

# Доход — п. 1 ст. 346.17 НК РФ, кассовый метод.
test_usn_income_expense_mode_income_fifteen_percent if {
	test_input := {
		"user": {"tax_mode": "USN_INCOME_EXPENSE"},
		"transaction": {
			"id": "t-usn15-income",
			"direction": "income",
			"amount": 80000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"description": "Оплата по договору",
		},
	}

	result.tax_rate == 0.15 with input as test_input
	result.needs_review == false with input as test_input
}

# Расход с подтверждающим документом — ст. 346.16 + ст. 252 НК РФ:
# документальное подтверждение есть → можно учитывать как расход без
# дополнительной проверки пользователем.
test_usn_expense_with_document_deductible if {
	test_input := {
		"user": {"tax_mode": "USN_INCOME_EXPENSE"},
		"transaction": {
			"id": "t-usn15-expense-doc",
			"direction": "expense",
			"amount": 20000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"description": "Аренда офиса",
			"linked_document": true,
		},
	}

	result == {
		"category": "business_expense",
		"taxable": false,
		"tax_rate": null,
		"deductible": true,
		"needs_review": false,
		"reason": "Ст. 346.16 и ст. 252 НК РФ: расход ИП на УСН 15%, документально подтверждён (договор/акт/счёт)",
	} with input as test_input
}

# Расход БЕЗ подтверждающего документа — ст. 252 НК РФ требует
# документального подтверждения расходов. Без документа учитывать как
# расход автоматически запрещено — deductible=false, needs_review=true.
test_usn_expense_without_document_needs_review if {
	test_input := {
		"user": {"tax_mode": "USN_INCOME_EXPENSE"},
		"transaction": {
			"id": "t-usn15-expense-nodoc",
			"direction": "expense",
			"amount": 20000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"description": "Разные расходы",
		},
	}

	result == {
		"category": "business_expense",
		"taxable": false,
		"tax_rate": null,
		"deductible": false,
		"needs_review": true,
		"reason": "Ст. 252 НК РФ: расход ИП на УСН 15% без документального подтверждения (нет договора/акта/счёта) — учёт как расхода требует подтверждения пользователя",
	} with input as test_input
}

# АУСН перенесён в tax.ausn.* (см. tax_ausn_test.rego) — здесь больше не
# тестируется, чтобы не было двух источников истины для одного режима.

# ==================================================
# SAFETY GUARD (deny)
# ==================================================

# Инвариант: ни одно правило в policy не оставляет reason пустым, поэтому
# safety guard deny не должен срабатывать ни на одном представленном
# сценарии. Это защита от РЕГРЕССИИ — если кто-то добавит новое правило
# с taxable=true/needs_review=false и забудет заполнить reason, deny
# должен сработать; здесь мы фиксируем, что на всех текущих правилах он
# молчит.
test_deny_does_not_fire_on_npd_company_income if {
	test_input := {
		"user": {"tax_mode": "NPD"},
		"transaction": {
			"id": "t-deny-1",
			"direction": "income",
			"amount": 50000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"description": "Оплата по договору",
		},
	}

	count(deny) == 0 with input as test_input
}

test_deny_does_not_fire_on_default_fallback if {
	test_input := {
		"user": {"tax_mode": "UNHANDLED_MODE"},
		"transaction": {
			"id": "t-deny-2",
			"direction": "income",
			"amount": 1000,
			"date": "2026-06-01",
			"counterparty_type": "bank",
			"description": "",
		},
	}

	count(deny) == 0 with input as test_input
}
