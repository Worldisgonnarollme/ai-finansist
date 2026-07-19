import 'package:intl/intl.dart';
import '../models/opa_tax_policy_input.dart';
import '../models/tax_mode.dart';
import '../models/transaction.dart';

final _dateFmt = DateFormat('yyyy-MM-dd');

const Map<TaxMode, String> _opaTaxModeByDartMode = {
  TaxMode.npd: 'NPD',
  TaxMode.usn6: 'USN_INCOME',
  TaxMode.usn15: 'USN_INCOME_EXPENSE',
  TaxMode.ausn8: 'AUSN_INCOME',
  TaxMode.ausn20: 'AUSN_INCOME_EXPENSE',
  TaxMode.osno: 'OSNO',
  TaxMode.psn: 'PSN',
  TaxMode.eshn: 'ESHN',
};

/// Строит вход для OPA из того, что реально известно о транзакции сегодня.
///
/// Возвращает null, если тип операции структурно не соответствует ни
/// "income", ни "expense" в схеме OPA (transfer/refund/cashback/
/// bank_interest/unknown) — для них вопрос "облагается по этому режиму"
/// не имеет смысла, и это не повод дёргать сеть.
///
/// related_to_business/linked_document/has_vat_invoice/counterparty_type и
/// все регимо-специфичные context-объекты (ausn/eshn/psn/npd) сейчас
/// НЕ заполняются: Transaction и AppState не хранят эти структурные факты
/// (см. project_ai_finansist memory — модель не расширялась под OPA).
/// Поэтому TaxPolicyInputValidator почти наверняка отклонит результат как
/// невалидный — это ОЖИДАЕМО и сознательно: лучше честно залогировать
/// "недостаточно данных", чем угадать факты и испортить сравнение, ради
/// которого затевался shadow-mode.
OpaTaxPolicyInput? mapTransactionToOpaInput(
  Transaction transaction,
  TaxMode taxMode, {
  bool? isIp,
}) {
  final direction = switch (transaction.type) {
    TransactionType.incomeIndividual ||
    TransactionType.incomeLegal ||
    TransactionType.income => 'income',
    TransactionType.expense => 'expense',
    _ => null,
  };
  if (direction == null) return null;

  final opaTaxMode = _opaTaxModeByDartMode[taxMode];
  if (opaTaxMode == null) return null;

  return OpaTaxPolicyInput(
    user: OpaUser(taxMode: opaTaxMode, isIp: isIp),
    transaction: OpaTransaction(
      id: transaction.id,
      direction: direction,
      amount: transaction.amount,
      date: _dateFmt.format(transaction.date),
    ),
  );
}
