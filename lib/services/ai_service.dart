import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tax_mode.dart';
import '../models/transaction.dart';

class AiService {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-haiku-4-5-20251001';

  final String? apiKey;

  AiService({this.apiKey});

  Future<List<Transaction>> classifyTransactions(
    List<Transaction> transactions,
  ) async {
    if (apiKey == null || apiKey!.isEmpty) {
      return _ruleBased(transactions);
    }

    // Отправляем на классификацию только то, что действительно неоднозначно —
    // знак (доход/расход) уже точно известен из банка/парсера/ручного ввода,
    // ИИ не должен его переопределять, видя только abs(amount).
    final toClassify = transactions
        .where(
          (t) =>
              t.type == TransactionType.income ||
              t.type == TransactionType.unknown,
        )
        .toList();
    if (toClassify.isEmpty) return transactions;

    try {
      final input = toClassify
          .map(
            (t) => {
              'id': t.id,
              'description': t.description,
              'amount': t.amount,
            },
          )
          .toList();

      const prompt = '''
Классифицируй операции самозанятого в России. Для каждой верни ОДИН тип
и краткое обоснование (reason, 3-7 слов, для аудита):
- income_individual: доход от физлица (оплата услуг, фриланс)
- income_legal: доход от юрлица или ИП (ООО, АО, ЗАО, ПАО, ИП — по договору/счёту)
- expense: расход (реклама, хостинг, оборудование, канцтовары)
- transfer: перевод между своими счетами
- refund: возврат средств от продавца или контрагента (возврат покупки, возврат по заказу)
- cashback: кэшбэк, бонусы банка, баллы лояльности
- bank_interest: проценты на остаток по счёту, доход по вкладу
- uncertain: нет однозначных признаков ни одной из категорий

ВАЖНО:
- refund, cashback и bank_interest НЕ облагаются НПД.
- Если нет уверенности в классификации — верни uncertain. НЕ угадывай
  income_individual/income_legal "на всякий случай": ошибочное отнесение
  личного перевода к доходу приведёт к неверному расчёту налога.
Верни ТОЛЬКО JSON массив: [{"id":"...","type":"...","reason":"..."}]

Операции:
''';

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': apiKey!,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': _model,
              'max_tokens': 2048,
              'messages': [
                {'role': 'user', 'content': '$prompt${jsonEncode(input)}'},
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = (data['content'] as List).first['text'] as String;
        final classified = jsonDecode(text) as List;
        return _apply(transactions, classified);
      }
    } catch (_) {}

    return _ruleBased(transactions);
  }

  List<Transaction> _apply(List<Transaction> txs, List classified) {
    final typeMap = <String, String>{};
    final reasonMap = <String, String>{};
    for (final item in classified) {
      final id = item['id'] as String;
      typeMap[id] = item['type'] as String;
      final reason = item['reason'];
      if (reason is String && reason.isNotEmpty) reasonMap[id] = reason;
    }
    return txs.map((tx) {
      final t = typeMap[tx.id];
      if (t == null) return tx;
      TransactionType type;
      switch (t) {
        case 'income_individual':
          type = TransactionType.incomeIndividual;
          break;
        case 'income_legal':
          type = TransactionType.incomeLegal;
          break;
        case 'expense':
          type = TransactionType.expense;
          break;
        case 'transfer':
          type = TransactionType.transfer;
          break;
        case 'refund':
          type = TransactionType.refund;
          break;
        case 'cashback':
          type = TransactionType.cashback;
          break;
        case 'bank_interest':
          type = TransactionType.bankInterest;
          break;
        case 'uncertain':
        default:
          // Защита от ошибочной классификации: нет уверенности — операция
          // НЕ попадает в налоговую базу автоматически (taxRelevance.undefined),
          // пока пользователь не разметит её вручную.
          type = TransactionType.unknown;
      }
      return tx.copyWith(
        type: type,
        justification:
            reasonMap[tx.id] ?? 'Классифицировано ИИ без обоснования',
      );
    }).toList();
  }

  List<Transaction> _ruleBased(List<Transaction> txs) {
    return txs.map((tx) {
      // CSV/PDF-парсеры и ручной ввод уже точно знают доход/расход по знаку
      // суммы в выписке (amount хранится по модулю, знак закодирован в type).
      // Уточнять описанием нужно только generic income (физлицо или юрлицо?)
      // и unknown — остальные типы трогать нельзя, иначе расход превратится
      // в доход.
      final needsClassification =
          tx.type == TransactionType.income ||
          tx.type == TransactionType.unknown;
      if (!needsClassification) return tx;

      final d = tx.description.toLowerCase();
      final isExcluded =
          d.contains('кэшбэк') ||
              d.contains('cashback') ||
              d.contains('cash back') ||
              d.contains('бонус от банка') ||
              d.contains('бонусные баллы')
          ? TransactionType.cashback
          : (d.contains('проценты на остаток') ||
                    d.contains('% на остаток') ||
                    d.contains('проценты по вкладу') ||
                    d.contains('доход по вкладу') ||
                    d.contains('начисление процент')
                ? TransactionType.bankInterest
                : (d.contains('возврат средств') ||
                          d.contains('возврат по заказу') ||
                          d.contains('возврат покупки') ||
                          d.contains('возврат по договору')
                      ? TransactionType.refund
                      : null));
      final isLegal =
          d.contains('ооо') ||
          d.contains(' ао ') ||
          d.contains('зао') ||
          d.contains('пао') ||
          d.contains('ип ') ||
          d.contains('по счёту') ||
          d.contains('по договору') ||
          d.contains('вознаграждение');

      TransactionType type;
      String justification;
      if (tx.type == TransactionType.income) {
        // Сумма уже точно доход (знак известен из выписки) — уточняем
        // только исключения из базы НПД и физлицо/юрлицо. Направление
        // (доход) не угадывается — оно уже подтверждено банком/парсером.
        if (isExcluded != null) {
          type = isExcluded;
          justification = 'Признак исключения из базы НПД по описанию операции';
        } else if (isLegal) {
          type = TransactionType.incomeLegal;
          justification = 'Признак юрлица/ИП в описании операции';
        } else {
          type = TransactionType.incomeIndividual;
          justification =
              'Доход подтверждён знаком суммы; плательщик не указан — принят как физлицо (консервативная ставка)';
        }
      } else {
        // tx.type == unknown — направление операции НЕ подтверждено.
        // Угадывать доход/расход здесь запрещено: ошибочное отнесение
        // личного перевода к доходу искажает налоговую базу. Если нет
        // явного признака — операция остаётся undefined и не участвует
        // в расчёте, пока пользователь не разметит её вручную.
        if (isExcluded != null) {
          type = isExcluded;
          justification = 'Признак исключения из базы НПД по описанию операции';
        } else if (isLegal) {
          type = TransactionType.incomeLegal;
          justification = 'Признак юрлица/ИП в описании операции';
        } else if (d.contains('реклам') ||
            d.contains('интернет') ||
            d.contains('хостинг') ||
            d.contains('google') ||
            d.contains('яндекс') ||
            d.contains('канц')) {
          type = TransactionType.expense;
          justification = 'Признак расхода по ключевому слову в описании';
        } else if (d.contains('перевод между')) {
          type = TransactionType.transfer;
          justification = 'Признак перевода между своими счетами';
        } else {
          type = TransactionType.unknown;
          justification =
              'Нет признаков дохода, расхода или исключения — требуется ручная проверка';
        }
      }
      return tx.copyWith(type: type, justification: justification);
    }).toList();
  }

  Future<String> generateAdvice({
    required double income,
    required double tax,
    required String taxMode,
    required DateTime date,
    required TaxMode mode,
    DateTime? registrationDate,
  }) async {
    if (apiKey == null || apiKey!.isEmpty) {
      return _staticAdvice(
        income: income,
        tax: tax,
        date: date,
        mode: mode,
        registrationDate: registrationDate,
      );
    }
    try {
      final prompt =
          'Самозанятый в России. Режим: $taxMode. Доход за месяц: '
          '${income.toStringAsFixed(0)} ₽, налог: ${tax.toStringAsFixed(0)} ₽, '
          'месяц: ${date.month}/${date.year}. '
          'Дай практичный совет 1-2 предложения. Без приветствий.';

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': apiKey!,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': _model,
              'max_tokens': 200,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['content'] as List).first['text'] as String;
      }
    } catch (_) {}
    return _staticAdvice(
      income: income,
      tax: tax,
      date: date,
      mode: mode,
      registrationDate: registrationDate,
    );
  }

  String _staticAdvice({
    required double income,
    required double tax,
    required DateTime date,
    required TaxMode mode,
    DateTime? registrationDate,
  }) {
    // ст. 55 НК РФ п. 2: ИП, зарегистрированный с 1 по 31 декабря, имеет
    // ПЕРВЫЙ налоговый период, продлённый до конца СЛЕДУЮЩЕГО года — доход
    // считается нарастающим итогом с даты регистрации, без обнуления
    // 1 января. Показываем в январе-феврале "продлённого" года — момент,
    // когда пользователь скорее всего ждёт "сброса" лимита и может быть
    // сбит с толку тем, что счётчик дохода продолжает расти.
    if (registrationDate != null &&
        registrationDate.month == 12 &&
        date.year == registrationDate.year + 1 &&
        date.month <= 2) {
      return 'Вы зарегистрированы в декабре ${registrationDate.year} — по '
          'ст. 55 НК РФ первый налоговый период продлён до конца '
          '${date.year} года. Доход считается нарастающим итогом с даты '
          'регистрации, лимиты и шкала НДФЛ не обнуляются 1 января.';
    }

    // ОСНО живёт по своему графику (авансы 28 июля/28 октября/28 января,
    // итог — 15 июля следующего года) — общие подсказки других режимов
    // (лимит НПД, "до 28-го числа следующего месяца") были бы для неё
    // неверны, поэтому разбираем отдельно.
    if (mode == TaxMode.osno) {
      if (date.month == 6 || date.month == 9 || date.month == 12) {
        return 'Через месяц — авансовый платёж по НДФЛ (28-е число). '
            'Не забудьте также про НДС за квартал.';
      }
      if (income > 45000000) {
        return 'Годовой доход приближается к 50 млн ₽ — после этого '
            'порога ставка НДФЛ на сумму сверх лимита вырастет до 22%.';
      }
      if (tax > 0) {
        return 'НДФЛ на ОСНО платится авансами (28 июля, 28 октября, '
            '28 января), итоговый расчёт — до 15 июля следующего года.';
      }
      return 'Подключите банк или добавьте операции — приложение '
          'рассчитает НДФЛ и НДС автоматически.';
    }
    // Стоимость патента не зависит от реального дохода — она считается
    // пропорционально числу месяцев действия патента (ст. 346.51 НК РФ,
    // п. 1), а не по факту заработанного. Взносы за себя её уменьшают
    // отдельно (ст. 346.51 НК РФ, п. 1.2) — этот факт настолько не
    // очевиден пользователям других режимов, что стоит явного напоминания.
    if (mode == TaxMode.psn && tax > 0) {
      return 'Стоимость патента фиксирована и считается пропорционально '
          'числу месяцев его действия, а не реальному доходу '
          '(ст. 346.51 НК РФ). Взносы за себя уменьшают её: без '
          'сотрудников — до 100%, с сотрудниками — до 50%.';
    }
    if (date.month >= 10) {
      if (mode == TaxMode.usn6) {
        return 'Оплатите страховые взносы до 28 декабря — на УСН '
            '«Доходы» они уменьшают сам налог: без сотрудников — до '
            '100%, с сотрудниками — до 50% (ст. 346.21 НК РФ, п. 3.1).';
      }
      if (mode == TaxMode.usn15) {
        return 'Оплатите страховые взносы до 28 декабря — на УСН '
            '«Доходы минус расходы» они включаются в состав расходов и '
            'уменьшают налоговую базу (ст. 346.16 НК РФ).';
      }
      return 'Оплатите страховые взносы до 28 декабря — это уменьшит налог за год.';
    }
    if (mode == TaxMode.npd && income > 2000000) {
      return 'Доход приближается к лимиту НПД (2.4 млн ₽). Рассмотрите открытие ИП на УСН.';
    }
    if (tax > 0) {
      return 'Оплатите налог до 28-го числа следующего месяца, чтобы избежать штрафов.';
    }
    return 'Подключите банк или добавьте операции — приложение рассчитает налог автоматически.';
  }
}
