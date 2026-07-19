package tax.osno

import rego.v1

# ==================================================
# DEFAULT / ANTI-HALLUCINATION
# ==================================================

test_decision_default_needs_review_true if {
	test_input := {
		"user": {"tax_mode": "OSNO"},
		"transaction": {
			"id": "t-decision-default",
			"direction": "income",
			"amount": 1000,
			"date": "2026-06-01",
			"counterparty_type": "bank",
		},
	}

	decision == {"needs_review": true} with input as test_input
}

# ==================================================
# INCOME-SCOPED DECISION
#
# direction == "income" требует уверенности income_tax + vat. expense
# вообще не участвует в этой ветке — direction операции не может быть
# одновременно "income" и "expense", поэтому требовать уверенности
# expense здесь означало бы фабриковать нерелевантное условие (см.
# ADR-0002, замена предыдущей версии агрегатора).
# ==================================================

test_decision_income_confident_when_income_tax_and_vat_confident if {
	test_input := {
		"user": {"tax_mode": "OSNO", "is_ip": true},
		"transaction": {
			"id": "t-decision-income",
			"direction": "income",
			"amount": 50000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"related_to_business": true,
			"vat_applicable": true,
			"has_vat_invoice": true,
		},
	}

	decision == {
		"income_tax": data.tax.osno.income_tax.result,
		"vat": data.tax.osno.vat.result,
		"needs_review": false,
	} with input as test_input

	decision.needs_review == false with input as test_input
}

# Если хотя бы один из income_tax/vat не уверен (здесь: vat_applicable
# отсутствует) — decision падает на default, а не подменяет недостающее
# поле выдуманным значением.
test_decision_income_needs_review_when_vat_unconfident if {
	test_input := {
		"user": {"tax_mode": "OSNO", "is_ip": true},
		"transaction": {
			"id": "t-decision-income-partial",
			"direction": "income",
			"amount": 50000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"related_to_business": true,
		},
	}

	decision == {"needs_review": true} with input as test_input
}

# ==================================================
# EXPENSE-SCOPED DECISION
# ==================================================

test_decision_expense_confident_when_expense_confident if {
	test_input := {
		"user": {"tax_mode": "OSNO"},
		"transaction": {
			"id": "t-decision-expense",
			"direction": "expense",
			"amount": 20000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"related_to_business": true,
			"linked_document": true,
			"excluded_under_art_270": false,
		},
	}

	decision == {
		"expense": data.tax.osno.expenses.result,
		"needs_review": false,
	} with input as test_input
}

test_decision_expense_needs_review_when_expense_unconfident if {
	test_input := {
		"user": {"tax_mode": "OSNO"},
		"transaction": {
			"id": "t-decision-expense-partial",
			"direction": "expense",
			"amount": 20000,
			"date": "2026-06-01",
			"counterparty_type": "company",
		},
	}

	decision == {"needs_review": true} with input as test_input
}
