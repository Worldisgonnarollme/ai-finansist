package tax.npd

import rego.v1

# ==================================================
# ELIGIBILITY
# ==================================================

test_eligibility_default_deny_when_no_data if {
	test_input := {"user": {"tax_mode": "NPD"}, "transaction": {"direction": "income"}}
	eligibility.compliant == false with input as test_input
}

npd_context_compliant := {
	"annual_income": 1000000,
	"has_employees": false,
	"is_resale": false,
	"sells_excisable_or_marked_goods": false,
	"mines_or_sells_minerals": false,
	"agent_scheme_without_exception": false,
	"combines_with_other_regime_same_activity": false,
}

test_eligibility_compliant_when_all_conditions_met if {
	test_input := {
		"user": {"tax_mode": "NPD"},
		"transaction": {"direction": "income"},
		"context": {"npd": npd_context_compliant},
	}
	eligibility.compliant == true with input as test_input
}

test_eligibility_deny_when_income_over_limit if {
	ctx := object.union(npd_context_compliant, {"annual_income": 3000000})
	test_input := {
		"user": {"tax_mode": "NPD"},
		"transaction": {"direction": "income"},
		"context": {"npd": ctx},
	}
	eligibility.compliant == false with input as test_input
}

test_eligibility_deny_when_has_employees if {
	ctx := object.union(npd_context_compliant, {"has_employees": true})
	test_input := {
		"user": {"tax_mode": "NPD"},
		"transaction": {"direction": "income"},
		"context": {"npd": ctx},
	}
	eligibility.compliant == false with input as test_input
}

test_eligibility_deny_when_resale if {
	ctx := object.union(npd_context_compliant, {"is_resale": true})
	test_input := {
		"user": {"tax_mode": "NPD"},
		"transaction": {"direction": "income"},
		"context": {"npd": ctx},
	}
	eligibility.compliant == false with input as test_input
}

# ==================================================
# EXPENSE — НЕ НАЛОГОВАЯ КАТЕГОРИЯ
# ==================================================

test_expense_always_non_compliant if {
	test_input := {"user": {"tax_mode": "NPD"}, "transaction": {"direction": "expense"}}
	expense.compliant == false with input as test_input
}

# ==================================================
# AGGREGATED DECISION
# ==================================================

test_decision_default_needs_review_when_no_data if {
	test_input := {"user": {"tax_mode": "NPD"}, "transaction": {"direction": "income"}}
	decision.needs_review == true with input as test_input
}

# Когда eligibility подтверждена, decision передаёт классификацию income
# из tax.policy без изменений (единый источник истины для ставок 4%/6%).
test_decision_passes_through_tax_policy_when_eligible if {
	test_input := {
		"user": {"tax_mode": "NPD"},
		"transaction": {
			"id": "t-npd-1",
			"direction": "income",
			"amount": 50000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"description": "Оплата по договору",
		},
		"context": {"npd": npd_context_compliant},
	}

	decision == data.tax.policy.result with input as test_input
	decision.needs_review == false with input as test_input
	decision.tax_rate == 0.06 with input as test_input
}

# Даже когда tax.policy уверенно классифицировал бы доход (контрагент —
# компания, ставка 6%), превышение лимита НПД должно блокировать
# автоматическое применение этой классификации.
test_decision_blocks_confident_classification_when_not_eligible if {
	ctx := object.union(npd_context_compliant, {"annual_income": 3000000})
	test_input := {
		"user": {"tax_mode": "NPD"},
		"transaction": {
			"id": "t-npd-2",
			"direction": "income",
			"amount": 50000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"description": "Оплата по договору",
		},
		"context": {"npd": ctx},
	}

	decision.needs_review == true with input as test_input
	decision != data.tax.policy.result with input as test_input
}

test_decision_expense_confident_non_taxable if {
	test_input := {"user": {"tax_mode": "NPD"}, "transaction": {"direction": "expense"}}
	decision.needs_review == false with input as test_input
}
