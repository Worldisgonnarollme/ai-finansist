import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum TransactionType { incomeIndividual, incomeLegal, income, expense, transfer, unknown }

enum TransactionSource { bank, csv, manual }

extension TransactionTypeExt on TransactionType {
  bool get isIncome =>
      this == TransactionType.incomeIndividual ||
      this == TransactionType.incomeLegal ||
      this == TransactionType.income;

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

  Transaction({
    String? id,
    required this.date,
    required this.amount,
    required this.description,
    required this.type,
    required this.source,
    this.bankName,
  }) : id = id ?? _uuid.v4();

  bool get isIncome => type.isIncome;

  Transaction copyWith({TransactionType? type}) => Transaction(
        id: id,
        date: date,
        amount: amount,
        description: description,
        type: type ?? this.type,
        source: source,
        bankName: bankName,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'amount': amount,
        'description': description,
        'type': type.name,
        'source': source.name,
        'bankName': bankName,
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
      );
}
