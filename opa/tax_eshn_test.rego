package tax.eshn

import rego.v1

# ==================================================
# ELIGIBILITY
# ==================================================

test_eligibility_default_deny_when_no_data if {
	test_input := {"user": {"tax_mode": "ESHN"}, "transaction": {"direction": "income"}}
	eligibility.compliant == false with input as test_input
}

test_eligibility_compliant_when_share_above_threshold if {
	test_input := {
		"user": {"tax_mode": "ESHN"},
		"transaction": {"direction": "income"},
		"context": {"eshn": {"agri_income_share": 0.85}},
	}
	eligibility.compliant == true with input as test_input
}

test_eligibility_deny_when_share_below_threshold if {
	test_input := {
		"user": {"tax_mode": "ESHN"},
		"transaction": {"direction": "income"},
		"context": {"eshn": {"agri_income_share": 0.50}},
	}
	eligibility.compliant == false with input as test_input
}

# ==================================================
# INCOME
# ==================================================

test_income_default_deny_when_not_confirmed if {
	test_input := {"user": {"tax_mode": "ESHN"}, "transaction": {"direction": "income"}}
	income.compliant == false with input as test_input
}

test_income_compliant_when_own_production if {
	test_input := {
		"user": {"tax_mode": "ESHN"},
		"transaction": {"direction": "income", "is_own_production": true},
	}
	income.compliant == true with input as test_input
}

test_income_deny_when_resale_not_own_production if {
	test_input := {
		"user": {"tax_mode": "ESHN"},
		"transaction": {"direction": "income", "is_own_production": false},
	}
	income.compliant == false with input as test_input
}

# ==================================================
# EXPENSE
# ==================================================

test_expense_default_deny_when_not_confirmed if {
	test_input := {"user": {"tax_mode": "ESHN"}, "transaction": {"direction": "expense"}}
	expense.compliant == false with input as test_input
}

test_expense_compliant_when_listed_under_346_5 if {
	test_input := {
		"user": {"tax_mode": "ESHN"},
		"transaction": {"direction": "expense", "included_under_art_346_5": true},
	}
	expense.compliant == true with input as test_input
}

# ==================================================
# VAT
# ==================================================

test_vat_compliant_by_default_as_active_payer if {
	test_input := {"user": {"tax_mode": "ESHN"}, "transaction": {"direction": "income"}}
	vat.compliant == true with input as test_input
}

test_vat_compliant_when_exemption_confirmed_below_threshold if {
	test_input := {
		"user": {"tax_mode": "ESHN"},
		"transaction": {"direction": "income"},
		"context": {"eshn": {"vat_exemption_claimed": true, "prior_year_income_excl_vat": 30000000}},
	}
	vat.compliant == true with input as test_input
}

test_vat_deny_when_exemption_claimed_above_threshold if {
	test_input := {
		"user": {"tax_mode": "ESHN"},
		"transaction": {"direction": "income"},
		"context": {"eshn": {"vat_exemption_claimed": true, "prior_year_income_excl_vat": 90000000}},
	}
	vat.compliant == false with input as test_input
}

# Заявлено освобождение, но порог не передан — система НЕ может его
# подтвердить, поэтому остаётся в безопасном default-состоянии "НДС
# действует" (а не ложно подтверждает непроверенное освобождение).
test_vat_stays_active_payer_when_exemption_claimed_but_unverifiable if {
	test_input := {
		"user": {"tax_mode": "ESHN"},
		"transaction": {"direction": "income"},
		"context": {"eshn": {"vat_exemption_claimed": true}},
	}
	vat.compliant == true with input as test_input
}

# ==================================================
# AGGREGATED DECISION
# ==================================================

test_decision_default_deny if {
	test_input := {"user": {"tax_mode": "ESHN"}, "transaction": {"direction": "income"}}
	decision == {"compliant": false} with input as test_input
}

test_decision_compliant_for_income_when_all_layers_compliant if {
	test_input := {
		"user": {"tax_mode": "ESHN"},
		"transaction": {"direction": "income", "is_own_production": true},
		"context": {"eshn": {"agri_income_share": 0.85}},
	}
	decision.compliant == true with input as test_input
}

test_decision_compliant_for_expense_when_all_layers_compliant if {
	test_input := {
		"user": {"tax_mode": "ESHN"},
		"transaction": {"direction": "expense", "included_under_art_346_5": true},
		"context": {"eshn": {"agri_income_share": 0.85}},
	}
	decision.compliant == true with input as test_input
}

test_decision_deny_when_eligibility_fails_even_if_income_confirmed if {
	test_input := {
		"user": {"tax_mode": "ESHN"},
		"transaction": {"direction": "income", "is_own_production": true},
		"context": {"eshn": {"agri_income_share": 0.30}},
	}
	decision == {"compliant": false} with input as test_input
}
