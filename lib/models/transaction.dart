import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum TransactionType {
  incomeIndividual,
  incomeLegal,
  income,
  expense,
  transfer,
  refund,
  cashback,
  bankInterest,
  unknown,
}

enum TransactionSource { bank, csv, manual }

// Источник истины: Налоговый кодекс РФ, разъяснения ФНС.
// Приложение НЕ принимает налоговых решений за пользователя — это
// производная (аудиторская) проекция над TransactionType, а не отдельное
// хранимое состояние. Расчёт налога продолжает использовать TransactionType
// напрямую (для ставок НПД физлицо/юрлицо); эти поля — для policy-проверок,
// логов и аудита.
enum TaxRelevance { taxable, nonTaxable, undefined }

enum TaxCategory { businessIncome, businessExpense, personalTransfer, ignored }

extension TransactionTypeExt on TransactionType {
  // Только налогооблагаемые поступления НПД
  bool get isIncome =>
      this == TransactionType.incomeIndividual ||
      this == TransactionType.incomeLegal ||
      this == TransactionType.income;

  // Поступления, не входящие в налоговую базу (ст. 6 422-ФЗ)
  bool get isExcluded =>
      this == TransactionType.refund ||
      this == TransactionType.cashback ||
      this == TransactionType.bankInterest;

  // Однозначно классифицированные типы — не требуют ручной проверки
  bool get isDefinite => this != TransactionType.unknown;

  TaxRelevance get taxRelevance {
    switch (this) {
      case TransactionType.incomeIndividual:
      case TransactionType.incomeLegal:
      case TransactionType.income:
      case TransactionType.expense:
        return TaxRelevance.taxable;
      case TransactionType.transfer:
      case TransactionType.refund:
      case TransactionType.cashback:
      case TransactionType.bankInterest:
        return TaxRelevance.nonTaxable;
      case TransactionType.unknown:
        return TaxRelevance.undefined;
    }
  }

  TaxCategory get category {
    switch (this) {
      case TransactionType.incomeIndividual:
      case TransactionType.incomeLegal:
      case TransactionType.income:
        return TaxCategory.businessIncome;
      case TransactionType.expense:
        return TaxCategory.businessExpense;
      case TransactionType.transfer:
        return TaxCategory.personalTransfer;
      case TransactionType.refund:
      case TransactionType.cashback:
      case TransactionType.bankInterest:
      case TransactionType.unknown:
        return TaxCategory.ignored;
    }
  }

  String get label {
    switch (this) {
      case TransactionType.incomeIndividual:
        return 'Доход от физлица';
      case TransactionType.incomeLegal:
        return 'Доход от юрлица/ИП';
      case TransactionType.income:
        return 'Доход';
      case TransactionType.expense:
        return 'Расход';
      case TransactionType.transfer:
        return 'Перевод';
      case TransactionType.refund:
        return 'Возврат';
      case TransactionType.cashback:
        return 'Кэшбэк';
      case TransactionType.bankInterest:
        return 'Проценты по счёту';
      case TransactionType.unknown:
        return 'Прочее';
    }
  }
}

class Transaction {
  final String id;
  final DateTime date;
  final double amount;
  final String description;
  final TransactionType type;
  final TransactionSource source;
  final String? bankName;
  // Краткое объяснение классификации — для аудита и логов
  final String? justification;
  // Выписка (BankStatement.id), из которой импортирована операция — null
  // для ручного ввода и операций из подключённого банка (source != csv).
  // Нужно, чтобы удаление выписки могло удалить именно её операции, а не
  // только запись о самой выписке (см. AppState.deleteStatement).
  final String? statementId;
  // Счёт банка (BankAccount.id), к которому отнесена операция — null для
  // операций, ещё не распределённых по счетам (ручной ввод, CSV, или банк
  // с ещё не сгенерированными счетами). Заполняется AppState при генерации
  // мок-счетов банка (см. AppState.ensureAccountsForBank/connectBank) — в
  // проекте нет реального банковского API, поэтому счета и привязка к ним
  // операций — заглушка на стороне приложения.
  final String? accountId;

  Transaction({
    String? id,
    required this.date,
    required this.amount,
    required this.description,
    required this.type,
    required this.source,
    this.bankName,
    this.justification,
    this.statementId,
    this.accountId,
  }) : id = id ?? _uuid.v4();

  bool get isIncome => type.isIncome;
  TaxRelevance get taxRelevance => type.taxRelevance;
  TaxCategory get category => type.category;

  Transaction copyWith({
    TransactionType? type,
    String? justification,
    String? statementId,
    String? accountId,
  }) => Transaction(
    id: id,
    date: date,
    amount: amount,
    description: description,
    type: type ?? this.type,
    source: source,
    bankName: bankName,
    justification: justification ?? this.justification,
    statementId: statementId ?? this.statementId,
    accountId: accountId ?? this.accountId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'amount': amount,
    'description': description,
    'type': type.name,
    'source': source.name,
    'bankName': bankName,
    'justification': justification,
    'statementId': statementId,
    'accountId': accountId,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    amount: (json['amount'] as num).toDouble(),
    description: json['description'] as String,
    type: TransactionType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => TransactionType.unknown,
    ),
    source: TransactionSource.values.firstWhere(
      (e) => e.name == json['source'],
      orElse: () => TransactionSource.manual,
    ),
    bankName: json['bankName'] as String?,
    justification: json['justification'] as String?,
    statementId: json['statementId'] as String?,
    accountId: json['accountId'] as String?,
  );
}
