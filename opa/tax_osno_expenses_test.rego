package tax.osno.expenses

import rego.v1

# ==================================================
# DEFAULT / ANTI-HALLUCINATION
# ==================================================

# Расход, не привязанный к бизнесу и без подтверждающего документа — нет
# оснований для deductible=true (ст. 252 НК РФ).
test_default_needs_review_when_undocumented if {
	test_input := {
		"user": {"tax_mode": "OSNO"},
		"transaction": {
			"id": "t-exp-default",
			"direction": "expense",
			"amount": 3000,
			"date": "2026-06-01",
			"counterparty_type": "company",
		},
	}

	result == {
		"deductible": false,
		"needs_review": true,
		"reason": "Нет достаточных оснований для учёта расхода по ОСНО",
		"legal_basis": [],
	} with input as test_input
}

# ==================================================
# DEDUCTIBLE EXPENSE
# ==================================================

test_deductible_when_documented_and_business_related if {
	test_input := {
		"user": {"tax_mode": "OSNO"},
		"transaction": {
			"id": "t-exp-deductible",
			"direction": "expense",
			"amount": 20000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"description": "Аренда офиса",
			"related_to_business": true,
			"linked_document": true,
			"excluded_under_art_270": false,
		},
	}

	result == {
		"deductible": true,
		"needs_review": false,
		"reason": "Расход документально подтверждён, связан с предпринимательской деятельностью и не входит в закрытый перечень расходов, не учитываемых при налогообложении по ОСНО",
		"legal_basis": ["НК РФ ст. 252", "НК РФ ст. 270"],
	} with input as test_input
}

# related_to_business=true без linked_document — ст. 252 НК РФ требует
# документального подтверждения, поэтому deductible остаётся false.
test_needs_review_when_business_related_but_undocumented if {
	test_input := {
		"user": {"tax_mode": "OSNO"},
		"transaction": {
			"id": "t-exp-nodoc",
			"direction": "expense",
			"amount": 7000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"related_to_business": true,
			"excluded_under_art_270": false,
		},
	}

	result.deductible == false with input as test_input
	result.needs_review == true with input as test_input
}

# ==================================================
# ИСКЛЮЧЁН ПО СТ. 270 НК РФ
# ==================================================

# Закрытый перечень ст. 270 НК РФ применяется независимо от обоснованности
# и документального подтверждения — это уверенное основание для
# deductible=false, а не "недостаточно данных".
test_not_deductible_when_excluded_under_art_270_even_if_documented if {
	test_input := {
		"user": {"tax_mode": "OSNO"},
		"transaction": {
			"id": "t-exp-art270",
			"direction": "expense",
			"amount": 15000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"related_to_business": true,
			"linked_document": true,
			"excluded_under_art_270": true,
		},
	}

	result == {
		"deductible": false,
		"needs_review": false,
		"reason": "Расход входит в закрытый перечень расходов, не учитываемых при налогообложении по ОСНО, независимо от обоснованности и документального подтверждения",
		"legal_basis": ["НК РФ ст. 270"],
	} with input as test_input
}
