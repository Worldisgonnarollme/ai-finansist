import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Расчётный счёт внутри подключённого банка — единственный тип счёта,
/// который ведёт ИП/ООО для бизнес-операций (никаких карт/вкладов).
/// Генерируется моком при подключении банка (см.
/// BankService.generateAccounts) — реальный банковский API не подключён,
/// как и для остальных данных в этом проекте.
class BankAccount {
  final String id;
  final String bankId;
  final String name;
  final String maskedNumber;

  BankAccount({
    String? id,
    required this.bankId,
    required this.name,
    required this.maskedNumber,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'bankId': bankId,
    'name': name,
    'maskedNumber': maskedNumber,
  };

  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
    id: json['id'] as String,
    bankId: json['bankId'] as String,
    name: json['name'] as String,
    maskedNumber: json['maskedNumber'] as String,
  );
}
