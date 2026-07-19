package tax.osno.income_tax

import rego.v1

# ==================================================
# DEFAULT / ANTI-HALLUCINATION
# ==================================================

# Без related_to_business у policy нет структурного основания признать
# доход облагаемым по ОСНО — операция уходит на ручную проверку.
test_default_needs_review_when_not_related_to_business if {
	test_input := {
		"user": {"tax_mode": "OSNO"},
		"transaction": {
			"id": "t-it-default",
			"direction": "income",
			"amount": 1000,
			"date": "2026-06-01",
			"counterparty_type": "bank",
		},
	}

	result == {
		"is_taxable_income": false,
		"needs_review": true,
		"reason": "Нет достаточных оснований для признания дохода по ОСНО",
		"legal_basis": [],
	} with input as test_input
}

# ==================================================
# BUSINESS INCOME — ИП vs ОРГАНИЗАЦИЯ
# ==================================================

test_taxable_when_ip_related_to_business if {
	test_input := {
		"user": {"tax_mode": "OSNO", "is_ip": true},
		"transaction": {
			"id": "t-it-ip",
			"direction": "income",
			"amount": 100000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"related_to_business": true,
		},
	}

	result == {
		"is_taxable_income": true,
		"needs_review": false,
		"reason": "Доход ИП от предпринимательской деятельности включается в налоговую базу по НДФЛ (ОСНО)",
		"legal_basis": ["НК РФ ст. 210"],
	} with input as test_input
}

test_taxable_when_organization_related_to_business if {
	test_input := {
		"user": {"tax_mode": "OSNO", "is_ip": false},
		"transaction": {
			"id": "t-it-org",
			"direction": "income",
			"amount": 100000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"related_to_business": true,
		},
	}

	result == {
		"is_taxable_income": true,
		"needs_review": false,
		"reason": "Доход организации от предпринимательской деятельности включается в налоговую базу по налогу на прибыль (ОСНО)",
		"legal_basis": ["НК РФ ст. 247"],
	} with input as test_input
}

# Без is_ip нет структурного основания выбрать ст. 210 (ИП) или ст. 247
# (организация) — операция остаётся на ручной проверке, а не угадывается.
test_needs_review_when_is_ip_unknown if {
	test_input := {
		"user": {"tax_mode": "OSNO"},
		"transaction": {
			"id": "t-it-no-is-ip",
			"direction": "income",
			"amount": 100000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"related_to_business": true,
		},
	}

	result.is_taxable_income == false with input as test_input
	result.needs_review == true with input as test_input
}

# Расход (не доход) с related_to_business=true не должен попадать под
# правило business income — этот пакет признаёт только direction == "income".
test_expense_does_not_match_business_income_rule if {
	test_input := {
		"user": {"tax_mode": "OSNO", "is_ip": true},
		"transaction": {
			"id": "t-it-expense",
			"direction": "expense",
			"amount": 5000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"related_to_business": true,
		},
	}

	result.is_taxable_income == false with input as test_input
	result.needs_review == true with input as test_input
}
