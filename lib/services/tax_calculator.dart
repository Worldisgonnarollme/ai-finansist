import '../models/transaction.dart';
import '../models/tax_period.dart';
import '../models/tax_mode.dart';

class TaxCalculator {
  static double calculateTax(List<Transaction> transactions, TaxMode mode) {
    double tax = 0;
    for (final tx in transactions) {
      if (!tx.isIncome) continue;
      switch (mode) {
        case TaxMode.npd:
          tax += tx.amount *
              (tx.type == TransactionType.incomeLegal ? 0.06 : 0.04);
          break;
        case TaxMode.usn6:
          tax += tx.amount * 0.06;
          break;
      }
    }
    return double.parse(tax.toStringAsFixed(2));
  }

  static List<TaxPeriod> groupByPeriods(
      List<Transaction> transactions, TaxMode mode) {
    final Map<String, List<Transaction>> grouped = {};
    for (final tx in transactions) {
      final key =
          '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final periods = grouped.entries.map((entry) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final txs = entry.value;
      final income =
          txs.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
      final expenses = txs
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);
      final tax = calculateTax(txs, mode);
      return TaxPeriod(
        year: year,
        month: month,
        income: income,
        expenses: expenses,
        tax: tax,
        transactionCount: txs.length,
      );
    }).toList();

    periods.sort((a, b) =>
        DateTime(b.year, b.month).compareTo(DateTime(a.year, a.month)));
    return periods;
  }
}
