/// Русское склонение по числительному: 1 → [one], 2–4 → [few], 5+/11–14 → [many].
String ruPlural(int n, String one, String few, String many) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return few;
  return many;
}

String ruOperations(int n) => '$n ${ruPlural(n, 'операция', 'операции', 'операций')}';

String ruMonths(int n) => '$n ${ruPlural(n, 'месяц', 'месяца', 'месяцев')}';

String ruFiles(int n) => '$n ${ruPlural(n, 'файл', 'файла', 'файлов')}';

String ruAccounts(int n) => '$n ${ruPlural(n, 'счёт', 'счёта', 'счетов')}';
