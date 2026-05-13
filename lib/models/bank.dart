import 'package:flutter/material.dart';

class Bank {
  final String id;
  final String name;
  final Color color;
  final bool isRecommended;

  const Bank({
    required this.id,
    required this.name,
    required this.color,
    this.isRecommended = false,
  });
}

class ConnectedBank {
  final String bankId;
  final String bankName;
  final DateTime connectedAt;

  ConnectedBank({
    required this.bankId,
    required this.bankName,
    required this.connectedAt,
  });

  Map<String, dynamic> toJson() => {
        'bankId': bankId,
        'bankName': bankName,
        'connectedAt': connectedAt.toIso8601String(),
      };

  factory ConnectedBank.fromJson(Map<String, dynamic> json) => ConnectedBank(
        bankId: json['bankId'] as String,
        bankName: json['bankName'] as String,
        connectedAt: DateTime.parse(json['connectedAt'] as String),
      );
}

const List<Bank> kSupportedBanks = [
  Bank(
    id: 'tinkoff',
    name: 'Т-Банк (Тинькофф)',
    color: Color(0xFFFFDD2D),
    isRecommended: true,
  ),
  Bank(id: 'sberbank', name: 'Сбербанк', color: Color(0xFF21A038)),
  Bank(id: 'alfa', name: 'Альфа-Банк', color: Color(0xFFEF3124)),
  Bank(id: 'vtb', name: 'ВТБ', color: Color(0xFF009FDF)),
  Bank(id: 'raiffeisen', name: 'Райффайзен', color: Color(0xFFFFED00)),
  Bank(id: 'gazprom', name: 'Газпромбанк', color: Color(0xFF0074C8)),
];
