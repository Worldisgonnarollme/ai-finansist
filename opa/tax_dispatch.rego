package tax

import rego.v1

############################################
# UNIFIED ENTRY POINT
#
# Маршрутизация по input.user.tax_mode. Default ниже срабатывает ТОЛЬКО
# когда ни одна из веток маршрутизации не сработала (например,
# input.user.tax_mode отсутствует целиком) — он никогда не переопределяет
# реальное решение, посчитанное в режимном пакете: needs_review/compliant
# оттуда прокидывается наверх без изменений.
#
# ОСНО, АУСН, ЕСХН, ПСН, НПД имеют собственные деревья пакетов
# (структурно отличаются от простой модели "один факт = taxable+tax_rate"
# — у каждого есть отдельный вопрос допустимости состояния/eligibility).
# tax.npd внутри себя переиспользует tax.policy.result для классификации
# ставок (единый источник истины), но гейтирует его через eligibility —
# поэтому НПД здесь маршрутизируется в tax.npd, а не прямо в tax.policy.
# Из общего tax.policy остаётся только УСН.
############################################

policy_modes := {"USN_INCOME", "USN_INCOME_EXPENSE"}

ausn_modes := {"AUSN_INCOME", "AUSN_INCOME_EXPENSE"}

default decision := {
	"needs_review": true,
	"reason": "Не удалось определить режим налогообложения пользователя (tax_mode отсутствует или не распознан)",
	"legal_basis": [],
}

decision := data.tax.osno.decision if {
	input.user.tax_mode == "OSNO"
}

decision := data.tax.ausn.decision if {
	input.user.tax_mode in ausn_modes
}

decision := data.tax.eshn.decision if {
	input.user.tax_mode == "ESHN"
}

decision := data.tax.psn.decision if {
	input.user.tax_mode == "PSN"
}

decision := data.tax.npd.decision if {
	input.user.tax_mode == "NPD"
}

decision := data.tax.policy.result if {
	input.user.tax_mode in policy_modes
}
