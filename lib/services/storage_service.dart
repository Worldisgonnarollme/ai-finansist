import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/bank.dart';
import '../models/bank_account.dart';
import '../models/bank_statement.dart';
import '../models/tax_mode.dart';
import '../models/tax_settings.dart';
import '../models/payment_period.dart';

class StorageService {
  static const _kName = 'user_name';
  static const _kPhone = 'user_phone';
  static const _kInn = 'user_inn';
  static const _kOgrnip = 'user_ogrnip';
  static const _kEmail = 'user_email';
  static const _kRegion = 'user_region';
  static const _kActivityType = 'user_activity_type';
  static const _kAvatar = 'user_avatar_base64';
  static const _kMode = 'tax_mode';
  static const _kDone = 'onboarding_done';
  static const _kTxs = 'transactions';
  static const _kBanks = 'connected_banks';
  static const _kApiKey = 'api_key';
  static const _kTaxSettings = 'tax_settings';
  static const _kStatements = 'bank_statements';
  static const _kAccounts = 'bank_accounts';
  static const _kPaymentPeriod = 'payment_period';

  final SharedPreferences _p;

  StorageService(this._p);

  static Future<StorageService> init() async =>
      StorageService(await SharedPreferences.getInstance());

  String get userName => _p.getString(_kName) ?? '';
  set userName(String v) => _p.setString(_kName, v);

  String get phoneNumber => _p.getString(_kPhone) ?? '';
  set phoneNumber(String v) => _p.setString(_kPhone, v);

  String get inn => _p.getString(_kInn) ?? '';
  set inn(String v) => _p.setString(_kInn, v);

  String get ogrnip => _p.getString(_kOgrnip) ?? '';
  set ogrnip(String v) => _p.setString(_kOgrnip, v);

  String get email => _p.getString(_kEmail) ?? '';
  set email(String v) => _p.setString(_kEmail, v);

  String get region => _p.getString(_kRegion) ?? '';
  set region(String v) => _p.setString(_kRegion, v);

  String get activityType => _p.getString(_kActivityType) ?? '';
  set activityType(String v) => _p.setString(_kActivityType, v);

  /// Фото профиля хранится как base64 прямо в SharedPreferences — в
  /// проекте нет облачного хранилища файлов (только Firebase Auth для
  /// личности, без Firestore/Storage), а локальное хранение всех прочих
  /// данных уже устроено так же (см. остальные поля этого класса).
  String get avatarBase64 => _p.getString(_kAvatar) ?? '';
  set avatarBase64(String v) => _p.setString(_kAvatar, v);

  TaxMode get taxMode => TaxMode.values.firstWhere(
    (e) => e.name == _p.getString(_kMode),
    orElse: () => TaxMode.npd,
  );
  set taxMode(TaxMode v) => _p.setString(_kMode, v.name);

  /// true, если режим уже когда-либо сохранялся (в отличие от [taxMode],
  /// который всегда возвращает значение, по умолчанию НПД).
  bool get hasTaxMode => _p.containsKey(_kMode);

  bool get onboardingDone => _p.getBool(_kDone) ?? false;
  set onboardingDone(bool v) => _p.setBool(_kDone, v);

  String get apiKey => _p.getString(_kApiKey) ?? '';
  set apiKey(String v) => _p.setString(_kApiKey, v);

  TaxSettings get taxSettings {
    final raw = _p.getString(_kTaxSettings);
    if (raw == null) return const TaxSettings();
    return TaxSettings.fromJsonString(raw);
  }

  set taxSettings(TaxSettings v) =>
      _p.setString(_kTaxSettings, jsonEncode(v.toJson()));

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

  List<BankStatement> get statements {
    final raw = _p.getString(_kStatements);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => BankStatement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  set statements(List<BankStatement> v) =>
      _p.setString(_kStatements, jsonEncode(v.map((e) => e.toJson()).toList()));

  List<BankAccount> get bankAccounts {
    final raw = _p.getString(_kAccounts);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => BankAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  set bankAccounts(List<BankAccount> v) =>
      _p.setString(_kAccounts, jsonEncode(v.map((e) => e.toJson()).toList()));

  PaymentPeriod get paymentPeriod => PaymentPeriod.values.firstWhere(
    (e) => e.name == _p.getString(_kPaymentPeriod),
    orElse: () => PaymentPeriod.month,
  );
  set paymentPeriod(PaymentPeriod v) => _p.setString(_kPaymentPeriod, v.name);

  void clearAll() => _p.clear();
}
