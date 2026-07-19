#!/usr/bin/env bash
# Guard: regime eligibility/qualification policy packages must classify
# (qualify) or validate compliance, never calculate. Tax amount calculation
# is a separate layer with separate ownership — OPA only answers "is this
# taxable / is this a VAT object / is this deductible / is this state
# compliant", never "how much tax is owed".
#
# Покрывает все режимы, у которых есть отдельное дерево пакетов
# (ОСНО, АУСН, ЕСХН, ПСН, НПД-eligibility) — УСН остаётся в
# tax_policy.rego, где tax_rate — допустимая законом константа режима
# (см. docs/adr/0001 и docs/adr/0007), а не вычисление. tax_npd.rego
# само ничего не считает (только переиспользует tax.policy.result), но
# проверяется здесь же для единообразия.
set -euo pipefail

cd "$(dirname "$0")"

guarded_files=(
  tax_osno.rego
  tax_osno_income_tax.rego
  tax_osno_vat.rego
  tax_osno_expenses.rego
  tax_ausn.rego
  tax_eshn.rego
  tax_psn.rego
  tax_npd.rego
)

fail=0

if grep -RIn "amount \*" "${guarded_files[@]}"; then
  echo "FAIL: found 'amount *' (tax amount calculation) in guarded policy files" >&2
  fail=1
fi

if grep -RIn "rate" "${guarded_files[@]}"; then
  echo "FAIL: found 'rate' (tax rate guessing) in guarded policy files" >&2
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  echo "These policies must only qualify/validate transactions, never compute tax amounts or rates." >&2
  exit 1
fi

echo "OK: no tax calculation or rate logic found in guarded policy files"
