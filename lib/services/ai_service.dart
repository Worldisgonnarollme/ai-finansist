import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';

class AiService {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-haiku-4-5-20251001';

  final String? apiKey;

  AiService({this.apiKey});

  Future<List<Transaction>> classifyTransactions(
      List<Transaction> transactions) async {
    if (apiKey == null || apiKey!.isEmpty) {
      return _ruleBased(transactions);
    }

    try {
      final input = transactions
          .map((t) => {'id': t.id, 'description': t.description, 'amount': t.amount})
          .toList();

      const prompt = '''
Классифицируй операции самозанятого в России. Для каждой верни тип:
- income_individual: доход от физлица
- income_legal: доход от юрлица или ИП
- expense: расход (реклама, услуги, оборудование)
- transfer: перевод между своими счетами

Верни ТОЛЬКО JSON массив: [{"id":"...","type":"..."}]

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
    final map = <String, String>{};
    for (final item in classified) {
      map[item['id'] as String] = item['type'] as String;
    }
    return txs.map((tx) {
      final t = map[tx.id];
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
        default:
          type = TransactionType.unknown;
      }
      return tx.copyWith(type: type);
    }).toList();
  }

  List<Transaction> _ruleBased(List<Transaction> txs) {
    return txs.map((tx) {
      if (tx.source == TransactionSource.bank &&
          tx.type != TransactionType.unknown) return tx;
      final d = tx.description.toLowerCase();
      TransactionType type;
      if (d.contains('ооо') ||
          d.contains(' ао ') ||
          d.contains('зао') ||
          d.contains('пао') ||
          d.contains('ип ') ||
          d.contains('по счёту') ||
          d.contains('по договору') ||
          d.contains('вознаграждение')) {
        type = TransactionType.incomeLegal;
      } else if (d.contains('реклам') ||
          d.contains('интернет') ||
          d.contains('хостинг') ||
          d.contains('google') ||
          d.contains('яндекс') ||
          d.contains('канц')) {
        type = TransactionType.expense;
      } else if (d.contains('перевод между')) {
        type = TransactionType.transfer;
      } else {
        type = tx.amount > 0
            ? TransactionType.incomeIndividual
            : TransactionType.expense;
      }
      return tx.copyWith(type: type);
    }).toList();
  }

  Future<String> generateAdvice({
    required double income,
    required double tax,
    required String taxMode,
    required DateTime date,
  }) async {
    if (apiKey == null || apiKey!.isEmpty) {
      return _staticAdvice(income: income, tax: tax, date: date);
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
    return _staticAdvice(income: income, tax: tax, date: date);
  }

  String _staticAdvice(
      {required double income, required double tax, required DateTime date}) {
    if (date.month >= 10) {
      return 'Оплатите страховые взносы до 31 декабря — это уменьшит налог за год.';
    }
    if (income > 2000000) {
      return 'Доход приближается к лимиту НПД (2.4 млн ₽). Рассмотрите открытие ИП на УСН.';
    }
    if (tax > 0) {
      return 'Оплатите налог до 28-го числа следующего месяца, чтобы избежать штрафов.';
    }
    return 'Подключите банк или добавьте операции — приложение рассчитает налог автоматически.';
  }
}
