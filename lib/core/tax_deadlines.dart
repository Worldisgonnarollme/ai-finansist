// Единый источник истины по срокам уплаты налогов в РФ — фиксированные
// даты, актуальные на 2026 год (реформа ЕНП унифицировала большинство
// сроков до 28-го числа месяца). Каждая дата ниже — константа
// (день/месяц), сверенная со статьёй НК РФ или профильного закона, а не
// подобранная на глаз. При изменении законодательства меняется только
// этот файл — все места приложения, которым нужен срок уплаты, должны
// брать его отсюда, а не заново хардкодить число.
//
// [TaxDeadlines.rollToWorkingDay] реализует общее правило переноса
// (ст. 6.1 НК РФ, п. 7): срок, выпавший на выходной или нерабочий
// праздничный день, переносится на ближайший следующий рабочий день.
// Учтён перенос с субботы/воскресенья и с фиксированных по датам
// федеральных праздников (Новогодние каникулы и Рождество — 1–8 января,
// 23 февраля, 8 марта, 1 и 9 мая, 12 июня, 4 ноября — ст. 112 ТК РФ).
// Ежегодный правительственный "перенос выходных дней" (когда суббота
// или воскресенье сами переносятся на другой будний день отдельным
// постановлением Правительства РФ, публикуемым на конкретный год) здесь
// НЕ воспроизводится — это не норма НК РФ и не фиксированные данные в
// том смысле, в каком их нужно "зашить" в код.
class TaxDeadlines {
  TaxDeadlines._();

  // ── ст. 6.1 НК РФ, п. 7 — перенос срока с выходного/праздника ─────

  static bool _isFixedHoliday(DateTime d) {
    if (d.month == 1 && d.day <= 8) return true; // Новый год + Рождество
    if (d.month == 2 && d.day == 23) return true; // День защитника Отечества
    if (d.month == 3 && d.day == 8) return true; // Международный женский день
    if (d.month == 5 && (d.day == 1 || d.day == 9)) return true; // Труда/Победы
    if (d.month == 6 && d.day == 12) return true; // День России
    if (d.month == 11 && d.day == 4) return true; // День народного единства
    return false;
  }

  /// Ближайший рабочий день начиная с [date] включительно.
  static DateTime rollToWorkingDay(DateTime date) {
    var d = date;
    while (d.weekday == DateTime.saturday ||
        d.weekday == DateTime.sunday ||
        _isFixedHoliday(d)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  // ── 1. ПСН — ст. 346.51 НК РФ, п. 2 ────────────────────────────────
  // Без промежуточных авансов — срок зависит от продолжительности патента.

  /// Патент до 6 месяцев — полная сумма в любой день до окончания срока
  /// действия; здесь возвращается последний допустимый день (сам конец
  /// срока действия патента).
  static DateTime psnUpTo6Months({
    required DateTime start,
    required int durationMonths,
  }) => rollToWorkingDay(
    DateTime(start.year, start.month + durationMonths, start.day),
  );

  /// Патент от 6 до 12 месяцев — двумя платежами: 1/3 стоимости в
  /// течение 90 календарных дней с даты начала, оставшиеся 2/3 — до
  /// 28 декабря текущего года.
  static ({DateTime first, DateTime second}) psn6To12Months({
    required DateTime start,
  }) => (
    first: rollToWorkingDay(start.add(const Duration(days: 90))),
    second: rollToWorkingDay(DateTime(start.year, 12, 28)),
  );

  // ── 2. НПД — ст. 11, п. 3 ФЗ № 422-ФЗ от 27.11.2018 ────────────────
  // Ежемесячно, не позднее 28-го числа месяца, следующего за истекшим.

  static DateTime npdDeadline(DateTime periodMonth) => rollToWorkingDay(
    periodMonth.month == 12
        ? DateTime(periodMonth.year + 1, 1, 28)
        : DateTime(periodMonth.year, periodMonth.month + 1, 28),
  );

  // ── 3. УСН — ст. 346.21 НК РФ, п. 7 ────────────────────────────────
  // Квартальные авансы одинаковы для ИП и ООО; итоговый срок различается.

  /// Авансовые платежи за I квартал / полугодие / 9 месяцев.
  static List<DateTime> usnQuarterlyAdvances(int year) => [
    rollToWorkingDay(DateTime(year, 4, 28)),
    rollToWorkingDay(DateTime(year, 7, 28)),
    rollToWorkingDay(DateTime(year, 10, 28)),
  ];

  /// Итоговый налог по результатам года: ИП — 28 апреля следующего
  /// года, ООО — 28 марта следующего года. Приложение считает налоги
  /// только для ИП (см. TaxSettings) — [isLegalEntity] оставлен для
  /// полноты справочных данных.
  static DateTime usnAnnualFinal({
    required int year,
    bool isLegalEntity = false,
  }) => rollToWorkingDay(
    isLegalEntity ? DateTime(year + 1, 3, 28) : DateTime(year + 1, 4, 28),
  );

  // ── 4. АУСН — ст. 12, п. 2 ФЗ № 17-ФЗ от 25.02.2022 ────────────────
  // Ежемесячно, не позднее 25-го числа месяца, следующего за периодом.

  static DateTime ausnDeadline(DateTime periodMonth) => rollToWorkingDay(
    periodMonth.month == 12
        ? DateTime(periodMonth.year + 1, 1, 25)
        : DateTime(periodMonth.year, periodMonth.month + 1, 25),
  );

  // ── 5. ОСНО ─────────────────────────────────────────────────────────

  /// Налог на прибыль (ООО) — ст. 287 НК РФ, п. 1. Упрощённый вариант
  /// (по фактической прибыли отчётного периода): 28 апреля/28 июля/
  /// 28 октября, итог за год — 28 марта следующего года. Приложение
  /// считает налоги только для ИП (НДФЛ, см. ниже) — эти константы
  /// оставлены для полноты справочных данных, если ООО добавят позже.
  /// (Альтернативный способ — ежемесячные авансы по расчётной прибыли —
  /// зависит от внутреннего решения налогоплательщика, а не от
  /// фиксированной календарной схемы, поэтому здесь не моделируется.)
  static List<DateTime> osnoProfitTaxAdvances(int year) => [
    rollToWorkingDay(DateTime(year, 4, 28)),
    rollToWorkingDay(DateTime(year, 7, 28)),
    rollToWorkingDay(DateTime(year, 10, 28)),
  ];

  static DateTime osnoProfitTaxAnnualFinal(int year) =>
      rollToWorkingDay(DateTime(year + 1, 3, 28));

  /// НДФЛ с доходов ИП на ОСНО — ст. 227 НК РФ, п. 6 и 8: авансы
  /// 28 апреля/28 июля/28 октября, итог за год — 15 июля следующего года.
  static List<DateTime> osnoNdflAdvances(int year) => [
    rollToWorkingDay(DateTime(year, 4, 28)),
    rollToWorkingDay(DateTime(year, 7, 28)),
    rollToWorkingDay(DateTime(year, 10, 28)),
  ];

  static DateTime osnoNdflAnnualFinal(int year) =>
      rollToWorkingDay(DateTime(year + 1, 7, 15));

  /// НДС (ИП и ООО) — ст. 174 НК РФ, п. 1: налог за истекший квартал
  /// делится на 3 равные части, каждая — до 28-го числа одного из трёх
  /// месяцев следующего квартала. [quarterEndMonth] — последний месяц
  /// закончившегося квартала (3, 6, 9 или 12).
  static List<DateTime> osnoVatInstallments({
    required int year,
    required int quarterEndMonth,
  }) => List.generate(3, (i) {
    final month = quarterEndMonth + 1 + i;
    return rollToWorkingDay(
      month > 12
          ? DateTime(year + 1, month - 12, 28)
          : DateTime(year, month, 28),
    );
  });

  // ── 6. ЕСХН — ст. 346.9 НК РФ, п. 2 и 5 ────────────────────────────
  // Один аванс за полугодие, итог — по результатам года.

  static DateTime eshnHalfYearAdvance(int year) =>
      rollToWorkingDay(DateTime(year, 7, 28));

  static DateTime eshnAnnualFinal(int year) =>
      rollToWorkingDay(DateTime(year + 1, 3, 28));
}
