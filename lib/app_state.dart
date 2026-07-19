import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'models/transaction.dart';
import 'models/bank.dart';
import 'models/bank_account.dart';
import 'models/bank_statement.dart';
import 'models/tax_period.dart';
import 'models/tax_mode.dart';
import 'models/tax_settings.dart';
import 'models/tax_result.dart';
import 'models/month_stat.dart';
import 'models/payment_period.dart';
import 'core/tax_deadlines.dart';
import 'core/tax_payment_flexibility.dart';
import 'services/tax_calculator.dart';
import 'services/storage_service.dart';
import 'services/ai_service.dart';
import 'services/bank_service.dart';
import 'services/csv_service.dart';
import 'services/pdf_service.dart';
import 'services/opa_client.dart';
import 'services/opa_shadow_mapper.dart';
import 'services/opa_shadow_logger.dart';
import 'services/tax_policy_input_validator.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage;
  late AiService _ai;

  // Shadow-mode OPA: выключен по умолчанию (null) — пока не развёрнут
  // настоящий OPA-сервер (opa run --server -b opa/), указывать сюда URL
  // не на что. Когда сервер появится, передать его адрес сюда (или через
  // конструктор/Settings) включит сравнение без единой строчки кода в
  // местах вызова _classifyWithShadow — оно уже подключено везде, где
  // вызывается AiService.classifyTransactions.
  static const Uri? _opaShadowBaseUrl = null;
  Future<OpaClient?>? _opaClientFuture;

  Future<OpaClient?> _ensureOpaClient() {
    final baseUrl = _opaShadowBaseUrl;
    if (baseUrl == null) return Future.value(null);
    return _opaClientFuture ??= TaxPolicyInputValidator.fromAsset().then(
      (validator) => OpaClient(baseUrl: baseUrl, validator: validator),
    );
  }

  /// Классифицирует через AiService и, если shadow-mode включён, для
  /// каждой транзакции с определённым типом (isDefinite) асинхронно
  /// сравнивает решение Dart (taxRelevance) с OPA — без ожидания
  /// (unawaited) и без какого-либо влияния на результат этого метода.
  Future<List<Transaction>> _classifyWithShadow(List<Transaction> raw) async {
    final classified = await _ai.classifyTransactions(raw);
    unawaited(_runOpaShadow(classified));
    return classified;
  }

  // Вся функция — фоновая, вызывается через unawaited(...) в
  // _classifyWithShadow и НЕ ДОЛЖНА позволить ни одной ошибке всплыть как
  // необработанная (даже не сетевой — например, если когда-нибудь
  // _opaShadowBaseUrl укажет на http:// вместо https:// и конструктор
  // OpaClient бросит ArgumentError, или asset со схемой не прочитается).
  // OpaClient.evaluateShadow уже сам ловит свои ошибки (сеть/таймаут), но
  // здесь дополнительно ловится всё остальное — это сознательный guard,
  // а не случайная защита за счёт Zone-поведения Dart.
  Future<void> _runOpaShadow(List<Transaction> transactions) async {
    try {
      final client = await _ensureOpaClient();
      if (client == null) return;
      for (final tx in transactions) {
        if (!tx.type.isDefinite) continue;
        final input = mapTransactionToOpaInput(
          tx,
          _taxMode,
          isIp: _taxMode != TaxMode.npd,
        );
        if (input == null) continue;
        final outcome = await client.evaluateShadow(input);
        logOpaShadowOutcome(tx, outcome);
      }
    } catch (e) {
      debugPrint(
        '[opa-shadow] unexpected error, shadow-mode disabled for this batch: $e',
      );
    }
  }

  String _userName = '';
  String _phoneNumber = '';
  String _inn = '';
  String _ogrnip = '';
  String _email = '';
  String _region = '';
  String _activityType = '';
  String _avatarBase64 = '';
  TaxMode _taxMode = TaxMode.npd;
  TaxSettings _taxSettings = const TaxSettings();
  PaymentPeriod _paymentPeriod = PaymentPeriod.month;
  List<ConnectedBank> _banks = [];
  List<Transaction> _transactions = [];
  List<BankStatement> _statements = [];
  List<BankAccount> _accounts = [];
  bool _onboardingDone = false;
  bool _loading = false;
  String? _error;
  String _advice = '';

  AppState(this._storage) {
    _userName = _storage.userName;
    _phoneNumber = _storage.phoneNumber;
    _inn = _storage.inn;
    _ogrnip = _storage.ogrnip;
    _email = _storage.email;
    _region = _storage.region;
    _activityType = _storage.activityType;
    _avatarBase64 = _storage.avatarBase64;
    _taxMode = _storage.taxMode;
    _taxSettings = _storage.taxSettings;
    // Восстановленный выбор мог стать недопустимым, если режим налога
    // менялся в другом месте (или в другой версии приложения) — сразу
    // приводим к ближайшему допустимому, а не полагаемся, что setTaxMode
    // всегда успел это сделать.
    _paymentPeriod = _coercePeriod(_storage.paymentPeriod, _taxMode);
    _banks = _storage.connectedBanks;
    _transactions = _storage.transactions;
    _statements = _storage.statements;
    _accounts = _storage.bankAccounts;
    _onboardingDone = _storage.onboardingDone;
    _ai = AiService(apiKey: _storage.apiKey);
    _migrateToSettlementAccountsOnly();
    if (_transactions.isNotEmpty) _refreshAdvice();
  }

  // Одноразовая (идемпотентная) миграция: раньше банк мог получить 2-3
  // счёта вперемешку (расчётный + дебетовая карта/накопительный), теперь
  // BankService.generateAccounts делает только один расчётный счёт (см.
  // задачу "в банках должны быть только расчётные счета"). Убирает у уже
  // подключённых банков старые счета других типов, оставляя/создавая ровно
  // один расчётный, и переносит на него операции с удаляемых счетов —
  // сама история операций не теряется, меняется только привязка к счёту.
  void _migrateToSettlementAccountsOnly() {
    var changed = false;
    for (final cb in _banks) {
      final bankAccounts = _accounts
          .where((a) => a.bankId == cb.bankId)
          .toList();
      final extra = bankAccounts
          .where((a) => a.name != 'Расчётный счёт')
          .toList();
      if (extra.isEmpty) continue;
      changed = true;

      BankAccount? existingSettlement;
      for (final a in bankAccounts) {
        if (a.name == 'Расчётный счёт') {
          existingSettlement = a;
          break;
        }
      }
      final settlement =
          existingSettlement ??
          BankAccount(
            bankId: cb.bankId,
            name: 'Расчётный счёт',
            maskedNumber: extra.first.maskedNumber,
          );
      final removedIds = extra.map((a) => a.id).toSet();

      _transactions = _transactions
          .map(
            (t) => removedIds.contains(t.accountId)
                ? t.copyWith(accountId: settlement.id)
                : t,
          )
          .toList();
      _accounts = [
        ..._accounts.where((a) => a.bankId != cb.bankId),
        settlement,
      ];
    }
    if (changed) {
      _storage.bankAccounts = _accounts;
      _storage.transactions = _transactions;
    }
  }

  // ── Getters ──────────────────────────────────────────────
  String get userName => _userName;
  String get phoneNumber => _phoneNumber;
  String get inn => _inn;
  String get ogrnip => _ogrnip;
  String get email => _email;
  String get region => _region;
  String get activityType => _activityType;
  String get avatarBase64 => _avatarBase64;
  TaxMode get taxMode => _taxMode;
  TaxSettings get taxSettings => _taxSettings;
  bool get hasTaxMode => _storage.hasTaxMode;
  PaymentPeriod get paymentPeriod => _paymentPeriod;
  PaymentFlexibility get paymentFlexibility => TaxPaymentFlexibility.of(_taxMode);
  List<ConnectedBank> get connectedBanks => List.unmodifiable(_banks);
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<BankStatement> get statements {
    final sorted = [..._statements]
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return List.unmodifiable(sorted);
  }

  bool get onboardingDone => _onboardingDone;
  bool get loading => _loading;
  String? get error => _error;
  String get advice => _advice;
  bool get hasBanks => _banks.isNotEmpty;

  List<BankAccount> accountsForBank(String bankId) =>
      _accounts.where((a) => a.bankId == bankId).toList();

  // ── Текущий период ────────────────────────────────────────
  DateTime get _now => DateTime.now();

  // Отображаемый месяц: текущий если есть данные, иначе последний с данными
  DateTime get displayMonth {
    final now = _now;
    final hasCurrent = _transactions.any(
      (t) => t.date.year == now.year && t.date.month == now.month,
    );
    if (hasCurrent || _transactions.isEmpty) return now;
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

  // ── Доходы/расходы ────────────────────────────────────────
  double get currentIncome => currentMonthTxs
      .where((t) => t.isIncome)
      .fold(0.0, (s, t) => s + t.amount);

  double get currentExpenses => currentMonthTxs
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  // Доход, накопленный в границах ТЕКУЩЕГО налогового периода (для
  // расчёта прогрессивных шкал — НДФЛ, НДС — и лимитов дохода по режиму).
  // Pre-validation policy: только taxRelevance.taxable + category.businessIncome
  // (t.isIncome). Личные переводы, кэшбэк/проценты/возврат и неразмеченные
  // (undefined) операции сюда НЕ попадают.
  //
  // По умолчанию период — календарный год. Исключение — ст. 55 НК РФ
  // п. 2: если ИП зарегистрирован в период с 1 по 31 декабря, ПЕРВЫЙ
  // налоговый период продлевается до конца СЛЕДУЮЩЕГО года — доход за
  // декабрь года регистрации и весь следующий год считается ОДНИМ
  // периодом, без обнуления 1 января. (Страховые взносы по ст. 430 НК РФ
  // этому правилу не подчиняются — там период всегда календарный год,
  // см. TaxCalculator._proratedFixedInsurance.)
  double get currentYearIncome {
    final now = _now;
    final reg = _taxSettings.registrationDate;
    if (reg != null && reg.month == 12 && now.year == reg.year + 1) {
      return _transactions
          .where((t) => t.isIncome && !t.date.isBefore(reg))
          .fold(0.0, (s, t) => s + t.amount);
    }
    final year = now.year;
    return _transactions
        .where((t) => t.isIncome && t.date.year == year)
        .fold(0.0, (s, t) => s + t.amount);
  }

  // ── Налоговый расчёт ──────────────────────────────────────
  TaxResult get currentTaxResult => TaxCalculator.calculate(
    periodTransactions: currentMonthTxs,
    annualIncome: currentYearIncome,
    mode: _taxMode,
    settings: _taxSettings,
    npdDeductionRemaining: _taxMode == TaxMode.npd
        ? _computeNpdDeductionRemaining()
        : 10000.0,
    year: _now.year,
  );

  // Вычисляет остаток налогового вычета 10 000 ₽ по итогам периодов
  // ДО текущего отображаемого месяца (нарастающим итогом)
  double _computeNpdDeductionRemaining() {
    const maxDeduction = 10000.0;
    double used = 0;
    final d = displayMonth;
    for (final tx in _transactions) {
      if (!tx.isIncome) continue;
      // Учитываем только месяцы строго РАНЬШЕ текущего периода
      if (tx.date.year > d.year) continue;
      if (tx.date.year == d.year && tx.date.month >= d.month) continue;
      final rate = tx.type == TransactionType.incomeLegal ? 0.02 : 0.01;
      used += tx.amount * rate;
      if (used >= maxDeduction) return 0;
    }
    return math.max(0.0, maxDeduction - used);
  }

  double get currentTax => currentTaxResult.netTax;

  double get currentInsurance => currentTaxResult.monthlyInsurance;

  // ── Выбор периода отображения (Месяц/Квартал/Год) ─────────
  // ТОЛЬКО отображение — реальный срок уплаты (paymentDue ниже) от этого
  // выбора не зависит и остаётся привязан к фактическому графику режима.
  // TaxCalculator.calculate уже умеет считать налог по любому диапазону
  // операций — здесь просто собирается диапазон нужной ширины и
  // передаётся periodMonths (для ПСН/вычета взносов УСН 6%, которые не
  // выводятся напрямую из суммы операций периода — см. tax_calculator.dart).

  int get _selectedPeriodMonths => switch (_paymentPeriod) {
    PaymentPeriod.month => 1,
    PaymentPeriod.quarter => _taxMode == TaxMode.eshn ? 6 : 3,
    PaymentPeriod.year => 12,
  };

  List<Transaction> get selectedPeriodTxs {
    final d = displayMonth;
    switch (_paymentPeriod) {
      case PaymentPeriod.month:
        return currentMonthTxs;
      case PaymentPeriod.quarter:
        final int startMonth;
        final int endMonth;
        if (_taxMode == TaxMode.eshn) {
          final half = d.month <= 6 ? 1 : 2;
          startMonth = half == 1 ? 1 : 7;
          endMonth = half == 1 ? 6 : 12;
        } else {
          final q = (d.month - 1) ~/ 3;
          startMonth = q * 3 + 1;
          endMonth = q * 3 + 3;
        }
        return _transactions
            .where(
              (t) =>
                  t.date.year == d.year &&
                  t.date.month >= startMonth &&
                  t.date.month <= endMonth,
            )
            .toList();
      case PaymentPeriod.year:
        return _transactions.where((t) => t.date.year == d.year).toList();
    }
  }

  TaxResult get selectedPeriodTaxResult => taxResultForTransactions(selectedPeriodTxs);

  // Пересчитывает налог за выбранный период по ПРОИЗВОЛЬНОМУ подмножеству
  // операций (например, только операции одного банка) — тем же режимом,
  // ставками и annualIncome (для корректной прогрессивной/маржинальной
  // математики: НДФЛ, НДС, НПД сверх лимита), что и общий налог бизнеса.
  // Используется для оценочной цифры "Налог с банка" на карточке банка
  // (см. BankSummaryCard) — это ОЦЕНКА, не отдельное юридическое
  // обязательство: налог в РФ считается на весь бизнес целиком, не по
  // банкам (сумма по всем банкам может не совпасть с общим налогом на
  // главной карточке — вычеты/пороги применяются к каждому подмножеству
  // независимо).
  TaxResult taxResultForTransactions(List<Transaction> txs) =>
      TaxCalculator.calculate(
        periodTransactions: txs,
        annualIncome: currentYearIncome,
        mode: _taxMode,
        settings: _taxSettings,
        npdDeductionRemaining: _taxMode == TaxMode.npd
            ? _computeNpdDeductionRemaining()
            : 10000.0,
        year: displayMonth.year,
        periodMonths: _selectedPeriodMonths,
      );

  static const List<String> _monthNamesRu = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  String get selectedPeriodLabel {
    final d = displayMonth;
    switch (_paymentPeriod) {
      case PaymentPeriod.month:
        return '${_monthNamesRu[d.month - 1]} ${d.year}';
      case PaymentPeriod.quarter:
        if (_taxMode == TaxMode.eshn) {
          final half = d.month <= 6 ? 'I' : 'II';
          return '$half полугодие ${d.year}';
        }
        const romanQuarters = ['I', 'II', 'III', 'IV'];
        final q = (d.month - 1) ~/ 3;
        return '${romanQuarters[q]} квартал ${d.year}';
      case PaymentPeriod.year:
        return '${d.year} год';
    }
  }

  // ── Срок оплаты ──────────────────────────────────────────
  // Источник всех дат — TaxDeadlines (lib/core/tax_deadlines.dart),
  // единственное место, где эти константы зашиты и сверены со статьями
  // НК РФ. Здесь только маршрутизация по режиму/периоду + перенос
  // выходного дня (ст. 6.1 НК РФ, п. 7) — он применяется внутри каждого
  // метода TaxDeadlines, а не дублируется тут.
  DateTime get paymentDue {
    final d = displayMonth;
    if (!_taxMode.isQuarterly) {
      // НПД — до 28-го, АУСН — до 25-го числа следующего месяца
      return _taxMode == TaxMode.npd
          ? TaxDeadlines.npdDeadline(d)
          : TaxDeadlines.ausnDeadline(d);
    }
    final now = _now;
    if (_taxMode == TaxMode.eshn) {
      // ЕСХН — не квартальные авансы: аванс за полугодие уплачивается
      // до 28 июля (уведомление об исчисленной сумме подаётся раньше,
      // до 25 июля, но это не срок уплаты), итоговый платёж за год —
      // до 28 марта следующего года (ст. 346.9 НК РФ, п. 2, 5).
      return now.month <= 6
          ? TaxDeadlines.eshnHalfYearAdvance(now.year)
          : TaxDeadlines.eshnAnnualFinal(now.year);
    }
    if (_taxMode == TaxMode.osno) {
      // ОСНО (НДФЛ для ИП) — свой график, отличный от УСН/ПСН: 3
      // квартальных аванса (28 апреля/28 июля/28 октября), итоговый
      // налог за год — отдельным платежом до 15 июля следующего года
      // (ст. 227 НК РФ, п. 6, 8).
      final advances = TaxDeadlines.osnoNdflAdvances(now.year);
      final annualFinal = TaxDeadlines.osnoNdflAnnualFinal(now.year);
      final quarter = (now.month - 1) ~/ 3;
      return quarter < advances.length ? advances[quarter] : annualFinal;
    }
    if (_taxMode == TaxMode.psn) {
      // ПСН не платит поквартальные авансы — срок зависит от даты начала
      // и длительности патента (1–12 месяцев внутри календарного года).
      final start = _taxSettings.patentStartDate;
      final duration = _taxSettings.patentDurationMonths;
      if (start == null) {
        // Дата начала патента не указана — консервативный запасной
        // вариант (конец года), пока пользователь не заполнит настройки.
        return TaxDeadlines.rollToWorkingDay(DateTime(now.year, 12, 28));
      }
      if (duration <= 6) {
        // Патент до 6 месяцев — единый платёж в любой день до окончания
        // срока действия патента.
        return TaxDeadlines.psnUpTo6Months(
          start: start,
          durationMonths: duration,
        );
      }
      // Патент от 6 до 12 месяцев — двумя платежами: 1/3 в течение
      // 90 календарных дней с даты начала, 2/3 — до 28 декабря текущего
      // года (единая дата независимо от даты начала).
      final schedule = TaxDeadlines.psn6To12Months(start: start);
      return now.isBefore(schedule.first) ? schedule.first : schedule.second;
    }
    // Квартальные авансовые платежи (УСН) + итог за год для ИП
    final advances = TaxDeadlines.usnQuarterlyAdvances(now.year);
    final annualFinal = TaxDeadlines.usnAnnualFinal(year: now.year);
    final quarter = (now.month - 1) ~/ 3;
    return quarter < advances.length ? advances[quarter] : annualFinal;
  }

  String get currentPeriodLabel {
    if (!_taxMode.isQuarterly) {
      const months = [
        'Январь',
        'Февраль',
        'Март',
        'Апрель',
        'Май',
        'Июнь',
        'Июль',
        'Август',
        'Сентябрь',
        'Октябрь',
        'Ноябрь',
        'Декабрь',
      ];
      final d = displayMonth;
      return '${months[d.month - 1]} ${d.year}';
    }
    if (_taxMode == TaxMode.eshn) {
      // ЕСХН отчитывается полугодиями, а не кварталами
      final half = _now.month <= 6 ? 'I' : 'II';
      return '$half полугодие ${_now.year}';
    }
    const romanQuarters = ['I', 'II', 'III', 'IV'];
    final quarter = (_now.month - 1) ~/ 3;
    return '${romanQuarters[quarter]} квартал ${_now.year}';
  }

  List<TaxPeriod> get periods =>
      TaxCalculator.groupByPeriods(_transactions, _taxMode, _taxSettings);

  List<Transaction> get recentTransactions {
    final sorted = [...currentMonthTxs]
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }

  List<MonthStat> get last6MonthsData {
    final anchor = displayMonth;
    return List.generate(6, (i) {
      final m = DateTime(anchor.year, anchor.month - (5 - i));
      final txs = _transactions
          .where((t) => t.date.year == m.year && t.date.month == m.month)
          .toList();
      final income = txs
          .where((t) => t.isIncome)
          .fold(0.0, (s, t) => s + t.amount);
      final expense = txs
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);
      return MonthStat(month: m, income: income, expense: expense);
    });
  }

  List<Transaction> txsForPeriod(int year, int month) =>
      _transactions
          .where((t) => t.date.year == year && t.date.month == month)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  // Ручная разметка операции с неопределённой классификацией —
  // единственный способ ввести undefined-операцию в налоговую базу.
  void reclassifyTransaction(String id, TransactionType type) {
    _transactions = _transactions.map((t) {
      if (t.id != id) return t;
      return t.copyWith(
        type: type,
        justification: 'Размечено пользователем вручную',
      );
    }).toList();
    _storage.transactions = _transactions;
    notifyListeners();
  }

  // ── Мутаторы ─────────────────────────────────────────────
  void setUserName(String v) {
    _userName = v;
    _storage.userName = v;
    notifyListeners();
  }

  void setPhoneNumber(String v) {
    _phoneNumber = v;
    _storage.phoneNumber = v;
    notifyListeners();
  }

  void setInn(String v) {
    _inn = v;
    _storage.inn = v;
    notifyListeners();
  }

  void setOgrnip(String v) {
    _ogrnip = v;
    _storage.ogrnip = v;
    notifyListeners();
  }

  void setEmail(String v) {
    _email = v;
    _storage.email = v;
    notifyListeners();
  }

  void setRegion(String v) {
    _region = v;
    _storage.region = v;
    notifyListeners();
  }

  void setActivityType(String v) {
    _activityType = v;
    _storage.activityType = v;
    notifyListeners();
  }

  void setAvatarBase64(String v) {
    _avatarBase64 = v;
    _storage.avatarBase64 = v;
    notifyListeners();
  }

  void setTaxMode(TaxMode v) {
    _taxMode = v;
    _storage.taxMode = v;
    // Выбранный период отображения (Месяц/Квартал/Год) мог стать
    // недопустимым в новом режиме (например "Квартал" при переходе на
    // НПД, где есть только помесячная уплата) — сбрасываем на ближайший
    // допустимый вместо того, чтобы молча показывать недействительный
    // выбор.
    final coerced = _coercePeriod(_paymentPeriod, v);
    if (coerced != _paymentPeriod) {
      _paymentPeriod = coerced;
      _storage.paymentPeriod = coerced;
    }
    // Совет зависит от режима (AiService.generateAdvice(mode: ...)) — без
    // пересчёта здесь он оставался бы от прежнего режима до следующей
    // операции с транзакциями (импорт/подключение банка и т.п.), из-за
    // чего пользователь на НПД видел совет про патент ПСН.
    _refreshAdvice();
    notifyListeners();
  }

  // Месяц разрешён абсолютно во всех режимах (см.
  // core/tax_payment_flexibility.dart) — безопасный запасной вариант.
  PaymentPeriod _coercePeriod(PaymentPeriod p, TaxMode mode) =>
      TaxPaymentFlexibility.of(mode).allows(p) ? p : PaymentPeriod.month;

  void setPaymentPeriod(PaymentPeriod p) {
    if (!paymentFlexibility.allows(p)) return;
    _paymentPeriod = p;
    _storage.paymentPeriod = p;
    notifyListeners();
  }

  void setTaxSettings(TaxSettings v) {
    _taxSettings = v;
    _storage.taxSettings = v;
    notifyListeners();
  }

  void completeOnboarding() {
    _onboardingDone = true;
    _storage.onboardingDone = true;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Счета банков (мок — реального банковского API нет) ────
  // Генерирует счета банка, если их ещё нет (идемпотентно — при повторном
  // вызове для банка, у которого счета уже есть, просто возвращает их).
  List<BankAccount> _ensureAccountsFor(Bank bank) {
    final existing = accountsForBank(bank.id);
    if (existing.isNotEmpty) return existing;
    final generated = BankService.generateAccounts(bank);
    _accounts = [..._accounts, ...generated];
    _storage.bankAccounts = _accounts;
    return generated;
  }

  // Раскладывает операции по счетам банка (round-robin) — реального
  // банковского API нет, поэтому привязка операции к конкретному счёту
  // условная, но нужна, чтобы экран счетов показывал не пустые карточки,
  // а доход/расход по каждому счёту.
  List<Transaction> _distributeAcrossAccounts(
    List<Transaction> txs,
    List<BankAccount> accounts,
  ) {
    if (accounts.isEmpty) return txs;
    return [
      for (var i = 0; i < txs.length; i++)
        txs[i].copyWith(accountId: accounts[i % accounts.length].id),
    ];
  }

  // Догенерирует счета для уже подключённого банка, если их почему-то нет
  // (например банк был подключён до появления этой фичи), и/или
  // распределяет по счетам операции банка, у которых ещё нет accountId
  // (банк мог быть подключён ПОСЛЕ того, как появились счета, но ДО того,
  // как появилось распределение операций по ним — счета в этом случае уже
  // есть, но операции остаются непривязанными). Идемпотентно: если
  // распределять нечего, ничего не делает. Вызывается из UI по кнопке
  // "Подробнее" на карточке банка (см. BankSummaryCard) — НЕ из build(),
  // чтобы notifyListeners() не сработал во время построения дерева виджетов.
  void ensureAccountsForBank(String bankId) {
    ConnectedBank? connected;
    for (final b in _banks) {
      if (b.bankId == bankId) {
        connected = b;
        break;
      }
    }
    if (connected == null) return;
    // bankId всегда приходит из ConnectedBank, а тот заполняется только из
    // kSupportedBanks (см. connectBank) — firstWhere не может не найти.
    final bank = kSupportedBanks.firstWhere((b) => b.id == bankId);
    final accounts = _ensureAccountsFor(bank);

    final hasUnassigned = _transactions.any(
      (t) => t.bankName == connected!.bankName && t.accountId == null,
    );
    if (!hasUnassigned) return;

    var i = 0;
    _transactions = _transactions.map((t) {
      if (t.bankName != connected!.bankName || t.accountId != null) return t;
      final acc = accounts[i % accounts.length];
      i++;
      return t.copyWith(accountId: acc.id);
    }).toList();
    _storage.transactions = _transactions;
    notifyListeners();
  }

  // ── Подключение банков ────────────────────────────────────
  Future<void> connectBank(Bank bank) async {
    _setLoading(true);
    try {
      final accounts = _ensureAccountsFor(bank);
      final raw = await BankService.connectAndFetch(bank);
      final distributed = _distributeAcrossAccounts(raw, accounts);
      final classified = await _classifyWithShadow(distributed);
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
            bankId: bank.id,
            bankName: bank.name,
            connectedAt: DateTime.now(),
          ),
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
        final bank = kSupportedBanks.firstWhere((b) => b.id == cb.bankId);
        final accounts = _ensureAccountsFor(bank);
        final raw = await BankService.connectAndFetch(bank);
        allNew.addAll(_distributeAcrossAccounts(raw, accounts));
      }
      final classified = await _classifyWithShadow(allNew);
      final nonBank = _transactions
          .where((t) => t.source != TransactionSource.bank)
          .toList();
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
      final classified = await _classifyWithShadow(parsed);
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

  Future<void> importFile(
    List<int> bytes,
    String extension, {
    String fileName = 'Выписка',
  }) async {
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
      final classified = await _classifyWithShadow(parsed);
      final existing = _transactions.map((t) => t.id).toSet();
      final statementId = const Uuid().v4();
      final added = classified
          .where((t) => !existing.contains(t.id))
          // Помечаем операции "своей" выпиской — без этого удаление
          // выписки (deleteStatement) не смогло бы найти, какие именно
          // операции удалить вместе с ней.
          .map((t) => t.copyWith(statementId: statementId))
          .toList();
      _transactions = [..._transactions, ...added];
      _storage.transactions = _transactions;

      final income = added
          .where((t) => t.isIncome)
          .fold(0.0, (s, t) => s + t.amount);
      final expenses = added
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);
      _statements = [
        ..._statements,
        BankStatement(
          id: statementId,
          fileName: fileName,
          extension: extension.toLowerCase(),
          uploadedAt: DateTime.now(),
          income: income,
          expenses: expenses,
          transactionCount: added.length,
        ),
      ];
      _storage.statements = _statements;

      await _refreshAdvice();
    } catch (e) {
      _error = 'Не удалось прочитать файл.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addManual(Transaction tx) async {
    final classified = await _classifyWithShadow([tx]);
    _transactions = [..._transactions, classified.first];
    _storage.transactions = _transactions;
    await _refreshAdvice();
    notifyListeners();
  }

  void disconnectBank(String bankId) {
    final bank = _banks.firstWhere((b) => b.bankId == bankId);
    _banks = _banks.where((b) => b.bankId != bankId).toList();
    _transactions = _transactions
        .where((t) => t.bankName != bank.bankName)
        .toList();
    _accounts = _accounts.where((a) => a.bankId != bankId).toList();
    _storage.connectedBanks = _banks;
    _storage.transactions = _transactions;
    _storage.bankAccounts = _accounts;
    notifyListeners();
  }

  // Удаляет выписку из списка ВМЕСТЕ с операциями, которые были добавлены
  // при её импорте (statementId) — иначе они остались бы в расчёте налога
  // после того, как сама выписка из списка пропала.
  void deleteStatement(String statementId) {
    _statements = _statements.where((s) => s.id != statementId).toList();
    _transactions = _transactions
        .where((t) => t.statementId != statementId)
        .toList();
    _storage.statements = _statements;
    _storage.transactions = _transactions;
    _refreshAdvice();
    notifyListeners();
  }

  void clearData() {
    _transactions = [];
    _banks = [];
    _accounts = [];
    _advice = '';
    _storage.clearAll();
    _onboardingDone = false;
    notifyListeners();
  }

  // ── Внутренние ───────────────────────────────────────────
  Future<void> _refreshAdvice() async {
    _advice = await _ai.generateAdvice(
      income: currentIncome,
      tax: currentTax,
      taxMode: _taxMode.displayName,
      date: _now,
      mode: _taxMode,
      registrationDate: _taxSettings.registrationDate,
    );
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
