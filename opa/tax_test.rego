package tax

import rego.v1

# ==================================================
# OSNO ROUTES TO ITS OWN DECISION TREE,
# NOT TO THE tax.policy GENERIC FALLBACK
# ==================================================

# Даже без структурных оснований (needs_review == true) decision для ОСНО
# должен иметь форму data.tax.osno.decision (income_tax/vat/expense), а не
# generic-форму tax.policy ({"category": "unknown", ...}). Это подтверждает,
# что ОСНО не обрабатывается fallback-логикой tax.policy.
test_osno_does_not_fall_back_to_tax_policy_shape if {
	test_input := {
		"user": {"tax_mode": "OSNO"},
		"transaction": {
			"id": "t-osno-default",
			"direction": "income",
			"amount": 1000,
			"date": "2026-06-01",
			"counterparty_type": "bank",
		},
	}

	not "category" in object.keys(decision) with input as test_input
	decision == data.tax.osno.decision with input as test_input
}

# ==================================================
# needs_review ИЗ ОСНО ПРОКИДЫВАЕТСЯ НАВЕРХ БЕЗ ИЗМЕНЕНИЙ
# ==================================================

test_osno_needs_review_passthrough_true if {
	test_input := {
		"user": {"tax_mode": "OSNO"},
		"transaction": {
			"id": "t-osno-nr-true",
			"direction": "income",
			"amount": 1000,
			"date": "2026-06-01",
			"counterparty_type": "bank",
		},
	}

	decision.needs_review == data.tax.osno.decision.needs_review with input as test_input
	decision.needs_review == true with input as test_input
}

# Структурный кейс, где income_tax и vat по отдельности уверенно
# классифицированы (needs_review=false у обоих) для одной income-операции —
# decision.needs_review для ОСНО равен false (см. tax_osno_test.rego), и
# dispatcher обязан передать именно это значение без изменений.
test_osno_needs_review_passthrough_matches_subpolicy_aggregate if {
	test_input := {
		"user": {"tax_mode": "OSNO", "is_ip": true},
		"transaction": {
			"id": "t-osno-nr-aggregate",
			"direction": "income",
			"amount": 50000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"related_to_business": true,
			"vat_applicable": true,
			"has_vat_invoice": true,
		},
	}

	decision.needs_review == data.tax.osno.decision.needs_review with input as test_input
	decision.needs_review == false with input as test_input
}

# ==================================================
# УСН ИДЁТ В tax.policy; ОСНО/АУСН/ЕСХН/ПСН/НПД — В СОБСТВЕННЫЕ ДЕРЕВЬЯ
# ==================================================

test_usn_routes_to_tax_policy if {
	test_input := {
		"user": {"tax_mode": "USN_INCOME"},
		"transaction": {
			"id": "t-usn-route",
			"direction": "income",
			"amount": 50000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"description": "Оплата по договору",
		},
	}

	decision == data.tax.policy.result with input as test_input
	decision.tax_rate == 0.06 with input as test_input
}

# НПД маршрутизируется в собственное дерево tax.npd (eligibility-гейт),
# которое внутри себя переиспользует tax.policy.result для классификации
# ставок — но dispatcher больше не ходит в tax.policy напрямую для НПД.
test_npd_routes_to_own_tree_not_tax_policy_directly if {
	test_input := {
		"user": {"tax_mode": "NPD"},
		"transaction": {"id": "t-npd-route", "direction": "income", "amount": 1000, "date": "2026-06-01", "counterparty_type": "bank"},
	}

	decision == data.tax.npd.decision with input as test_input
}

test_ausn_routes_to_own_tree_not_tax_policy if {
	test_input := {
		"user": {"tax_mode": "AUSN_INCOME"},
		"transaction": {"id": "t-ausn-route", "direction": "income", "amount": 1000, "date": "2026-06-01", "counterparty_type": "bank"},
	}

	not "category" in object.keys(decision) with input as test_input
	decision == data.tax.ausn.decision with input as test_input
}

test_eshn_routes_to_own_tree_not_tax_policy if {
	test_input := {
		"user": {"tax_mode": "ESHN"},
		"transaction": {"id": "t-eshn-route", "direction": "income", "amount": 1000, "date": "2026-06-01", "counterparty_type": "bank"},
	}

	not "category" in object.keys(decision) with input as test_input
	decision == data.tax.eshn.decision with input as test_input
}

test_psn_routes_to_own_tree_not_tax_policy if {
	test_input := {
		"user": {"tax_mode": "PSN"},
		"transaction": {"id": "t-psn-route", "direction": "income", "amount": 1000, "date": "2026-06-01", "counterparty_type": "bank"},
	}

	not "category" in object.keys(decision) with input as test_input
	decision == data.tax.psn.decision with input as test_input
}

# ==================================================
# tax_mode ОТСУТСТВУЕТ ЦЕЛИКОМ — DISPATCHER-LEVEL DEFAULT
#
# Ни одна из двух веток маршрутизации не может сработать, если
# input.user.tax_mode отсутствует вовсе (а не просто невалиден) — этот
# default — единственная защита от undefined на самом верхнем уровне.
# Он не переопределяет ничьё реальное решение, т.к. срабатывает только
# когда обе явные ветки не сработали.
# ==================================================

test_dispatcher_default_when_tax_mode_missing if {
	test_input := {
		"user": {},
		"transaction": {
			"id": "t-no-tax-mode",
			"direction": "income",
			"amount": 1000,
			"date": "2026-06-01",
			"counterparty_type": "bank",
		},
	}

	decision == {
		"needs_review": true,
		"reason": "Не удалось определить режим налогообложения пользователя (tax_mode отсутствует или не распознан)",
		"legal_basis": [],
	} with input as test_input
}
