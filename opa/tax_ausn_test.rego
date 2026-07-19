package tax.ausn

import rego.v1

# ==================================================
# ELIGIBILITY
# ==================================================

test_eligibility_default_deny_when_no_data if {
	test_input := {"user": {"tax_mode": "AUSN_INCOME"}, "transaction": {"direction": "income"}}
	eligibility.compliant == false with input as test_input
}

test_eligibility_compliant_when_all_limits_met if {
	test_input := {
		"user": {"tax_mode": "AUSN_INCOME"},
		"transaction": {"direction": "income"},
		"context": {"ausn": {
			"pilot_region_confirmed": true,
			"annual_income": 10000000,
			"avg_headcount": 3,
			"residual_fixed_assets_value": 5000000,
			"has_branches": false,
			"excluded_activity": false,
		}},
	}
	eligibility.compliant == true with input as test_input
}

test_eligibility_deny_when_income_over_limit if {
	test_input := {
		"user": {"tax_mode": "AUSN_INCOME"},
		"transaction": {"direction": "income"},
		"context": {"ausn": {
			"pilot_region_confirmed": true,
			"annual_income": 70000000,
			"avg_headcount": 3,
			"residual_fixed_assets_value": 5000000,
			"has_branches": false,
			"excluded_activity": false,
		}},
	}
	eligibility.compliant == false with input as test_input
}

# ==================================================
# INCOME
# ==================================================

test_income_default_deny_when_unconfirmed if {
	test_input := {"user": {"tax_mode": "AUSN_INCOME"}, "transaction": {"direction": "income"}}
	income.compliant == false with input as test_input
}

test_income_compliant_when_confirmed_by_bank if {
	test_input := {
		"user": {"tax_mode": "AUSN_INCOME"},
		"transaction": {"direction": "income", "confirmed_by": "authorized_bank"},
	}
	income.compliant == true with input as test_input
}

test_income_compliant_when_confirmed_by_kkt if {
	test_input := {
		"user": {"tax_mode": "AUSN_INCOME_EXPENSE"},
		"transaction": {"direction": "income", "confirmed_by": "kkt"},
	}
	income.compliant == true with input as test_input
}

# ==================================================
# EXPENSE
# ==================================================

test_expense_compliant_for_income_expense_object_when_confirmed if {
	test_input := {
		"user": {"tax_mode": "AUSN_INCOME_EXPENSE"},
		"transaction": {"direction": "expense", "confirmed_by": "authorized_bank"},
	}
	expense.compliant == true with input as test_input
}

test_expense_deny_for_income_only_object_even_if_confirmed if {
	test_input := {
		"user": {"tax_mode": "AUSN_INCOME"},
		"transaction": {"direction": "expense", "confirmed_by": "authorized_bank"},
	}
	expense.compliant == false with input as test_input
	expense.reason == "Для объекта «доходы» АУСН расходы не являются налоговой категорией" with input as test_input
}

# ==================================================
# VAT
# ==================================================

test_vat_compliant_by_default_when_not_applicable if {
	test_input := {"user": {"tax_mode": "AUSN_INCOME"}, "transaction": {"direction": "income"}}
	vat.compliant == true with input as test_input
}

test_vat_deny_when_applicable_without_exception if {
	test_input := {
		"user": {"tax_mode": "AUSN_INCOME"},
		"transaction": {"direction": "income", "vat_applicable": true},
	}
	vat.compliant == false with input as test_input
}

test_vat_compliant_when_applicable_with_import_exception if {
	test_input := {
		"user": {"tax_mode": "AUSN_INCOME"},
		"transaction": {"direction": "income", "vat_applicable": true, "vat_exception": "import_vat"},
	}
	vat.compliant == true with input as test_input
}

# ==================================================
# AGGREGATED DECISION
# ==================================================

test_decision_default_deny if {
	test_input := {"user": {"tax_mode": "AUSN_INCOME"}, "transaction": {"direction": "income"}}
	decision == {"compliant": false} with input as test_input
}

test_decision_compliant_for_income_when_all_layers_compliant if {
	test_input := {
		"user": {"tax_mode": "AUSN_INCOME"},
		"transaction": {"direction": "income", "confirmed_by": "authorized_bank"},
		"context": {"ausn": {
			"pilot_region_confirmed": true,
			"annual_income": 10000000,
			"avg_headcount": 3,
			"residual_fixed_assets_value": 5000000,
			"has_branches": false,
			"excluded_activity": false,
		}},
	}
	decision.compliant == true with input as test_input
}

test_decision_compliant_for_expense_when_all_layers_compliant if {
	test_input := {
		"user": {"tax_mode": "AUSN_INCOME_EXPENSE"},
		"transaction": {"direction": "expense", "confirmed_by": "authorized_bank"},
		"context": {"ausn": {
			"pilot_region_confirmed": true,
			"annual_income": 10000000,
			"avg_headcount": 3,
			"residual_fixed_assets_value": 5000000,
			"has_branches": false,
			"excluded_activity": false,
		}},
	}
	decision.compliant == true with input as test_input
}

test_decision_deny_when_eligibility_fails_even_if_income_confirmed if {
	test_input := {
		"user": {"tax_mode": "AUSN_INCOME"},
		"transaction": {"direction": "income", "confirmed_by": "authorized_bank"},
	}
	decision == {"compliant": false} with input as test_input
}
