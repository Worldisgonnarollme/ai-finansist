package tax.psn

import rego.v1

# ==================================================
# ELIGIBILITY
# ==================================================

test_eligibility_default_deny_when_no_data if {
	test_input := {"user": {"tax_mode": "PSN"}, "transaction": {"direction": "income"}}
	eligibility.compliant == false with input as test_input
}

test_eligibility_compliant_when_ip_and_limits_met_no_hall if {
	test_input := {
		"user": {"tax_mode": "PSN", "is_ip": true},
		"transaction": {"direction": "income"},
		"context": {"psn": {
			"regional_activity_allowed": true,
			"annual_income_all_patents": 10000000,
			"avg_headcount_all_patents": 5,
			"hall_area_applicable": false,
		}},
	}
	eligibility.compliant == true with input as test_input
}

test_eligibility_compliant_when_hall_area_within_limit if {
	test_input := {
		"user": {"tax_mode": "PSN", "is_ip": true},
		"transaction": {"direction": "income"},
		"context": {"psn": {
			"regional_activity_allowed": true,
			"annual_income_all_patents": 10000000,
			"avg_headcount_all_patents": 5,
			"hall_area_applicable": true,
			"hall_area": 80,
		}},
	}
	eligibility.compliant == true with input as test_input
}

test_eligibility_deny_when_hall_area_over_limit if {
	test_input := {
		"user": {"tax_mode": "PSN", "is_ip": true},
		"transaction": {"direction": "income"},
		"context": {"psn": {
			"regional_activity_allowed": true,
			"annual_income_all_patents": 10000000,
			"avg_headcount_all_patents": 5,
			"hall_area_applicable": true,
			"hall_area": 200,
		}},
	}
	eligibility.compliant == false with input as test_input
}

test_eligibility_deny_when_not_ip if {
	test_input := {
		"user": {"tax_mode": "PSN", "is_ip": false},
		"transaction": {"direction": "income"},
		"context": {"psn": {
			"regional_activity_allowed": true,
			"annual_income_all_patents": 10000000,
			"avg_headcount_all_patents": 5,
			"hall_area_applicable": false,
		}},
	}
	eligibility.compliant == false with input as test_input
}

test_eligibility_deny_when_income_over_limit if {
	test_input := {
		"user": {"tax_mode": "PSN", "is_ip": true},
		"transaction": {"direction": "income"},
		"context": {"psn": {
			"regional_activity_allowed": true,
			"annual_income_all_patents": 70000000,
			"avg_headcount_all_patents": 5,
			"hall_area_applicable": false,
		}},
	}
	eligibility.compliant == false with input as test_input
}

# ==================================================
# INCOME
# ==================================================

test_income_default_deny_when_not_confirmed if {
	test_input := {"user": {"tax_mode": "PSN"}, "transaction": {"direction": "income"}}
	income.compliant == false with input as test_input
}

test_income_compliant_when_covered_by_patent if {
	test_input := {
		"user": {"tax_mode": "PSN"},
		"transaction": {"direction": "income", "activity_covered_by_patent": true},
	}
	income.compliant == true with input as test_input
}

# ==================================================
# EXPENSE — НИКОГДА НЕ ДОПУСТИМ
# ==================================================

test_expense_always_non_compliant if {
	test_input := {"user": {"tax_mode": "PSN"}, "transaction": {"direction": "expense"}}
	expense.compliant == false with input as test_input
}

# ==================================================
# VAT
# ==================================================

test_vat_compliant_by_default if {
	test_input := {"user": {"tax_mode": "PSN"}, "transaction": {"direction": "income"}}
	vat.compliant == true with input as test_input
}

test_vat_deny_when_applicable_without_exception if {
	test_input := {
		"user": {"tax_mode": "PSN"},
		"transaction": {"direction": "income", "vat_applicable": true},
	}
	vat.compliant == false with input as test_input
}

test_vat_compliant_when_applicable_with_agent_exception if {
	test_input := {
		"user": {"tax_mode": "PSN"},
		"transaction": {"direction": "income", "vat_applicable": true, "vat_exception": "tax_agent_vat"},
	}
	vat.compliant == true with input as test_input
}

# ==================================================
# AGGREGATED DECISION
# ==================================================

test_decision_default_deny if {
	test_input := {"user": {"tax_mode": "PSN"}, "transaction": {"direction": "income"}}
	decision == {"compliant": false} with input as test_input
}

test_decision_compliant_for_income_when_all_layers_compliant if {
	test_input := {
		"user": {"tax_mode": "PSN", "is_ip": true},
		"transaction": {"direction": "income", "activity_covered_by_patent": true},
		"context": {"psn": {
			"regional_activity_allowed": true,
			"annual_income_all_patents": 10000000,
			"avg_headcount_all_patents": 5,
			"hall_area_applicable": false,
		}},
	}
	decision.compliant == true with input as test_input
}

test_decision_expense_always_non_compliant_even_with_eligibility if {
	test_input := {
		"user": {"tax_mode": "PSN", "is_ip": true},
		"transaction": {"direction": "expense"},
		"context": {"psn": {
			"regional_activity_allowed": true,
			"annual_income_all_patents": 10000000,
			"avg_headcount_all_patents": 5,
			"hall_area_applicable": false,
		}},
	}
	decision.compliant == false with input as test_input
}
