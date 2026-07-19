import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Загруженный файл выписки (CSV/PDF) и агрегированные по нему доходы/
/// расходы — считаются один раз в момент импорта, не пересчитываются.
class BankStatement {
  final String id;
  final String fileName;
  final String extension;
  final DateTime uploadedAt;
  final double income;
  final double expenses;
  final int transactionCount;

  BankStatement({
    String? id,
    required this.fileName,
    required this.extension,
    required this.uploadedAt,
    required this.income,
    required this.expenses,
    required this.transactionCount,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'extension': extension,
    'uploadedAt': uploadedAt.toIso8601String(),
    'income': income,
    'expenses': expenses,
    'transactionCount': transactionCount,
  };

  factory BankStatement.fromJson(Map<String, dynamic> json) => BankStatement(
    id: json['id'] as String,
    fileName: json['fileName'] as String,
    extension: json['extension'] as String,
    uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    income: (json['income'] as num).toDouble(),
    expenses: (json['expenses'] as num).toDouble(),
    transactionCount: json['transactionCount'] as int,
  );
}
