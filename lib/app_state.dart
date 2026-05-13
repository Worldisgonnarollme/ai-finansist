import 'package:flutter/foundation.dart';
import 'models/transaction.dart';
import 'models/bank.dart';
import 'models/tax_period.dart';
import 'models/tax_mode.dart';
import 'models/month_stat.dart';
import 'services/tax_calculator.dart';
import 'services/storage_service.dart';
import 'services/ai_service.dart';
import 'services/bank_service.dart';
import 'services/csv_service.dart';
import 'services/pdf_service.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage;
  late AiService _ai;

  String _userName = '';
  TaxMode _taxMode = TaxMode.npd;
  List<ConnectedBank> _banks = [];
  List<Transaction> _transactions = [];
  bool _onboardingDone = false;
  bool _loading = false;
  String? _error;
  String _advice = '';
  bool _isDark = true;

  AppState(this._storage) {
    _userName = _storage.userName;
    _taxMode = _storage.taxMode;
    _banks = _storage.connectedBanks;
    _transactions = _storage.transactions;
    _onboardingDone = _storage.onboardingDone;
    _isDark = _storage.isDark;
    _ai = AiService(apiKey: _storage.apiKey);
    if (_transactions.isNotEmpty) _refreshAdvice();
  }

  // ── Getters ──────────────────────────────────────────────
  String get userName => _userName;
  TaxMode get taxMode => _taxMode;
  List<ConnectedBank> get connectedBanks => List.unmodifiable(_banks);
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  bool get onboardingDone => _onboardingDone;
  bool get loading => _loading;
  String? get error => _error;
  String get advice => _advice;
  bool get hasBanks => _banks.isNotEmpty;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    _storage.isDark = _isDark;
    notifyListeners();
  }

  // ── Current month computed ────────────────────────────────
  DateTime get _now => DateTime.now();

  // Returns the displayed period: current month if it has data,
  // otherwise the most recent month that does.
  DateTime get displayMonth {
    final now = _now;
    final hasCurrent = _transactions.any(
        (t) => t.date.year == now.year && t.date.month == now.month);
    if (hasCurrent || _transactions.isEmpty) return now;
    // Find most recent month with transactions
    final latest = _transactions
        .map((t) => DateTime(t.date.year, t.date.month))
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return latest;
  }

  List<Transaction> get currentMonthTxs {
    final d = displayMonth;
    return _transactions
        .where((t) => t.date.year == d.year && t.date.month == d.month)
        .toList();
  }

  bool get isShowingCurrentMonth {
    final d = displayMonth;
    return d.year == _now.year && d.month == _now.month;
  }

  double get currentIncome => currentMonthTxs
      .where((t) => t.isIncome)
      .fold(0.0, (s, t) => s + t.amount);

  double get currentExpenses => currentMonthTxs
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  double get currentTax =>
      TaxCalculator.calculateTax(currentMonthTxs, _taxMode);

  DateTime get paymentDue {
    final d = displayMonth;
    return d.month == 12
        ? DateTime(d.year + 1, 1, 28)
        : DateTime(d.year, d.month + 1, 28);
  }

  List<TaxPeriod> get periods =>
      TaxCalculator.groupByPeriods(_transactions, _taxMode);

  List<MonthStat> get last6MonthsData {
    final now = _now;
    return List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i));
      final txs = _transactions
          .where((t) => t.date.year == m.year && t.date.month == m.month)
          .toList();
      final income = txs.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
      final expense = txs
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);
      return MonthStat(month: m, income: income, expense: expense);
    });
  }

  List<Transaction> txsForPeriod(int year, int month) => _transactions
      .where((t) => t.date.year == year && t.date.month == month)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  // ── Mutators ──────────────────────────────────────────────
  void setUserName(String v) {
    _userName = v;
    _storage.userName = v;
    notifyListeners();
  }

  void setTaxMode(TaxMode v) {
    _taxMode = v;
    _storage.taxMode = v;
    notifyListeners();
  }

  void completeOnboarding() {
    _onboardingDone = true;
    _storage.onboardingDone = true;
    notifyListeners();
  }

  void setApiKey(String key) {
    _storage.apiKey = key;
    _ai = AiService(apiKey: key);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Bank connection ───────────────────────────────────────
  Future<void> connectBank(Bank bank) async {
    _setLoading(true);
    try {
      final raw = await BankService.connectAndFetch(bank);
      final classified = await _ai.classifyTransactions(raw);
      final existing = _transactions.map((t) => t.id).toSet();
      _transactions = [
        ..._transactions,
        ...classified.where((t) => !existing.contains(t.id)),
      ];
      _storage.transactions = _transactions;

      if (!_banks.any((b) => b.bankId == bank.id)) {
        _banks = [
          ..._banks,
          ConnectedBank(
              bankId: bank.id, bankName: bank.name, connectedAt: DateTime.now()),
        ];
        _storage.connectedBanks = _banks;
      }
      await _refreshAdvice();
    } catch (e) {
      _error = 'Не удалось подключить банк. Попробуйте позже.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshData() async {
    if (_banks.isEmpty) return;
    _setLoading(true);
    try {
      final allNew = <Transaction>[];
      for (final cb in _banks) {
        final bank =
            kSupportedBanks.firstWhere((b) => b.id == cb.bankId);
        allNew.addAll(await BankService.connectAndFetch(bank));
      }
      final classified = await _ai.classifyTransactions(allNew);
      final nonBank =
          _transactions.where((t) => t.source != TransactionSource.bank).toList();
      _transactions = [...nonBank, ...classified];
      _storage.transactions = _transactions;
      await _refreshAdvice();
    } catch (_) {
      _error = 'Не удалось обновить данные.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> importCsv(String content) async {
    _setLoading(true);
    try {
      final parsed = CsvService.parse(content);
      if (parsed.isEmpty) {
        _error = 'Не удалось распознать операции в файле. Проверьте формат.';
        notifyListeners();
        return;
      }
      final classified = await _ai.classifyTransactions(parsed);
      _transactions = [..._transactions, ...classified];
      _storage.transactions = _transactions;
      await _refreshAdvice();
    } catch (e) {
      _error = 'Не удалось прочитать файл.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> importFile(List<int> bytes, String extension) async {
    _setLoading(true);
    try {
      List<Transaction> parsed;
      if (extension.toLowerCase() == 'pdf') {
        parsed = PdfService.parseBytes(bytes);
      } else {
        parsed = CsvService.parseBytes(bytes);
      }
      if (parsed.isEmpty) {
        _error = 'Не удалось распознать операции в файле. Проверьте формат.';
        notifyListeners();
        return;
      }
      final classified = await _ai.classifyTransactions(parsed);
      final existing = _transactions.map((t) => t.id).toSet();
      _transactions = [
        ..._transactions,
        ...classified.where((t) => !existing.contains(t.id)),
      ];
      _storage.transactions = _transactions;
      await _refreshAdvice();
    } catch (e) {
      _error = 'Не удалось прочитать файл.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addManual(Transaction tx) async {
    final classified = await _ai.classifyTransactions([tx]);
    _transactions = [..._transactions, classified.first];
    _storage.transactions = _transactions;
    await _refreshAdvice();
    notifyListeners();
  }

  void disconnectBank(String bankId) {
    final bank = _banks.firstWhere((b) => b.bankId == bankId);
    _banks = _banks.where((b) => b.bankId != bankId).toList();
    _transactions =
        _transactions.where((t) => t.bankName != bank.bankName).toList();
    _storage.connectedBanks = _banks;
    _storage.transactions = _transactions;
    notifyListeners();
  }

  void clearData() {
    _transactions = [];
    _banks = [];
    _advice = '';
    _storage.clearAll();
    _onboardingDone = false;
    notifyListeners();
  }

  // ── Internal ──────────────────────────────────────────────
  Future<void> _refreshAdvice() async {
    _advice = await _ai.generateAdvice(
      income: currentIncome,
      tax: currentTax,
      taxMode: _taxMode.displayName,
      date: _now,
    );
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
