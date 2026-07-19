package tax.osno.vat

import rego.v1

# ==================================================
# DEFAULT / ANTI-HALLUCINATION
# ==================================================

# Без vat_applicable нет структурного основания признать операцию объектом
# обложения НДС (ст. 146 НК РФ) — наличие счёта-фактуры на это не влияет,
# это вопрос совсем другой статьи (168/169).
test_default_needs_review_when_not_vat_applicable if {
	test_input := {
		"user": {"tax_mode": "OSNO"},
		"transaction": {
			"id": "t-vat-default",
			"direction": "income",
			"amount": 12000,
			"date": "2026-06-01",
			"counterparty_type": "company",
		},
	}

	result == {
		"vat_object": false,
		"needs_review": true,
		"reason": "Невозможно однозначно определить объект обложения НДС",
		"legal_basis": [],
		"invoice_documented": false,
		"invoice_legal_basis": [],
	} with input as test_input
}

# ==================================================
# VAT OBJECT DETECTED — НЕЗАВИСИМО ОТ СЧЁТА-ФАКТУРЫ
#
# ст. 146 НК РФ не ставит объект обложения НДС в зависимость от наличия
# счёта-фактуры — это требование к документообороту (ст. 168/169), а не
# условие возникновения объекта налога. has_vat_invoice влияет только на
# отдельное поле invoice_documented, не на vat_object.
# ==================================================

test_vat_object_detected_with_invoice if {
	test_input := {
		"user": {"tax_mode": "OSNO"},
		"transaction": {
			"id": "t-vat-invoice",
			"direction": "income",
			"amount": 12000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"vat_applicable": true,
			"has_vat_invoice": true,
		},
	}

	result == {
		"vat_object": true,
		"needs_review": false,
		"reason": "Реализация товаров, работ или услуг признаётся объектом обложения НДС",
		"legal_basis": ["НК РФ ст. 146"],
		"invoice_documented": true,
		"invoice_legal_basis": ["НК РФ ст. 168", "НК РФ ст. 169"],
	} with input as test_input
}

test_vat_object_detected_without_invoice if {
	test_input := {
		"user": {"tax_mode": "OSNO"},
		"transaction": {
			"id": "t-vat-no-invoice",
			"direction": "income",
			"amount": 12000,
			"date": "2026-06-01",
			"counterparty_type": "company",
			"vat_applicable": true,
			"has_vat_invoice": false,
		},
	}

	result == {
		"vat_object": true,
		"needs_review": false,
		"reason": "Реализация товаров, работ или услуг признаётся объектом обложения НДС",
		"legal_basis": ["НК РФ ст. 146"],
		"invoice_documented": false,
		"invoice_legal_basis": ["НК РФ ст. 168", "НК РФ ст. 169"],
	} with input as test_input
}
