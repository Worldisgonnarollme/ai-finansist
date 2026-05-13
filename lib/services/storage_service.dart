import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/bank.dart';
import '../models/tax_mode.dart';

class StorageService {
  static const _kName = 'user_name';
  static const _kMode = 'tax_mode';
  static const _kDone = 'onboarding_done';
  static const _kTxs = 'transactions';
  static const _kBanks = 'connected_banks';
  static const _kApiKey = 'api_key';
  static const _kDark = 'theme_is_dark';

  final SharedPreferences _p;

  StorageService(this._p);

  static Future<StorageService> init() async =>
      StorageService(await SharedPreferences.getInstance());

  String get userName => _p.getString(_kName) ?? '';
  set userName(String v) => _p.setString(_kName, v);

  TaxMode get taxMode => TaxMode.values.firstWhere(
        (e) => e.name == _p.getString(_kMode),
        orElse: () => TaxMode.npd,
      );
  set taxMode(TaxMode v) => _p.setString(_kMode, v.name);

  bool get onboardingDone => _p.getBool(_kDone) ?? false;
  set onboardingDone(bool v) => _p.setBool(_kDone, v);

  String get apiKey => _p.getString(_kApiKey) ?? '';
  set apiKey(String v) => _p.setString(_kApiKey, v);

  List<Transaction> get transactions {
    final raw = _p.getString(_kTxs);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  set transactions(List<Transaction> v) =>
      _p.setString(_kTxs, jsonEncode(v.map((e) => e.toJson()).toList()));

  List<ConnectedBank> get connectedBanks {
    final raw = _p.getString(_kBanks);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => ConnectedBank.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  set connectedBanks(List<ConnectedBank> v) =>
      _p.setString(_kBanks, jsonEncode(v.map((e) => e.toJson()).toList()));

  bool get isDark => _p.getBool(_kDark) ?? true;
  set isDark(bool v) => _p.setBool(_kDark, v);

  void clearAll() => _p.clear();
}
