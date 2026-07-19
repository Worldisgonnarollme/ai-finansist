import 'dart:math';
import '../models/transaction.dart';
import '../models/bank.dart';
import '../models/bank_account.dart';

class BankService {
  static final _rng = Random();

  static Future<List<Transaction>> connectAndFetch(Bank bank) async {
    await Future.delayed(const Duration(seconds: 3));
    return _generateMock(bank);
  }

  // Мок-счёт банка — только расчётный счёт (единственный тип, который
  // ведёт ИП/ООО для бизнес-операций; никаких карт и вкладов). Генерируется
  // один раз при подключении банка и дальше хранится как есть (см.
  // AppState.connectBank) — реального банковского API нет.
  static List<BankAccount> generateAccounts(Bank bank) {
    return [
      BankAccount(
        bankId: bank.id,
        name: 'Расчётный счёт',
        maskedNumber: '•• ${1000 + _rng.nextInt(9000)}',
      ),
    ];
  }

  static List<Transaction> _generateMock(Bank bank) {
    final now = DateTime.now();
    final txs = <Transaction>[];

    const incomeData = [
      ('Оплата услуг от Иванов А.П.', TransactionType.incomeIndividual),
      ('Перевод за консультацию Петров С.И.', TransactionType.incomeIndividual),
      ('Оплата по договору ООО "Ромашка"', TransactionType.incomeLegal),
      ('Вознаграждение ИП Сидоров К.В.', TransactionType.incomeLegal),
      ('Оплата услуг Козлов В.Н.', TransactionType.incomeIndividual),
      ('Проект от Новикова А.А.', TransactionType.incomeIndividual),
      ('Услуги по счёту ООО "Стройтех"', TransactionType.incomeLegal),
      ('Разработка Морозов Д.К.', TransactionType.incomeIndividual),
      ('АО "МедиаГрупп" по договору', TransactionType.incomeLegal),
      ('Дизайн Соколов М.Р.', TransactionType.incomeIndividual),
      ('ООО "Цифра" оплата услуг', TransactionType.incomeLegal),
      ('Консультация Лебедев П.А.', TransactionType.incomeIndividual),
    ];

    const expenseData = [
      ('Реклама Яндекс.Директ', TransactionType.expense),
      ('Интернет МТС', TransactionType.expense),
      ('Канцтовары DNS', TransactionType.expense),
      ('Google Workspace', TransactionType.expense),
      ('Хостинг Timeweb', TransactionType.expense),
    ];

    for (int mo = 0; mo < 3; mo++) {
      final base = DateTime(now.year, now.month - mo, 1);
      final daysInMonth = DateTime(base.year, base.month + 1, 0).day;
      final count = 5 + _rng.nextInt(7);

      for (int i = 0; i < count; i++) {
        final day = 1 + _rng.nextInt(daysInMonth);
        final date = DateTime(base.year, base.month, day);
        if (date.isAfter(now)) continue;
        final pick = incomeData[_rng.nextInt(incomeData.length)];
        final amount = 15000 + _rng.nextInt(85000).toDouble();
        txs.add(
          Transaction(
            date: date,
            amount: amount,
            description: pick.$1,
            type: pick.$2,
            source: TransactionSource.bank,
            bankName: bank.name,
          ),
        );
      }

      final expCount = _rng.nextInt(3);
      for (int i = 0; i < expCount; i++) {
        final day = 1 + _rng.nextInt(daysInMonth);
        final date = DateTime(base.year, base.month, day);
        if (date.isAfter(now)) continue;
        final pick = expenseData[_rng.nextInt(expenseData.length)];
        final amount = 500 + _rng.nextInt(9500).toDouble();
        txs.add(
          Transaction(
            date: date,
            amount: amount,
            description: pick.$1,
            type: pick.$2,
            source: TransactionSource.bank,
            bankName: bank.name,
          ),
        );
      }
    }

    return txs;
  }
}
