class TaxPeriod {
  final int year;
  final int month;
  final double income;
  final double expenses;
  final double tax;
  final int transactionCount;

  TaxPeriod({
    required this.year,
    required this.month,
    required this.income,
    required this.expenses,
    required this.tax,
    required this.transactionCount,
  });

  static const _months = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  String get name => '${_months[month - 1]} $year';

  DateTime get paymentDueDate =>
      month == 12 ? DateTime(year + 1, 1, 28) : DateTime(year, month + 1, 28);
}
