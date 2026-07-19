import '../../../models/tax_mode.dart';

/// Ставки и лимиты продублированы из [TaxModeExt] в виде готовых для UI
/// строк (эталонные тексты docs/design/tax_regime_*_v3.html) — сверять с
/// НК РФ вместе с TaxModeExt при изменении ставок.

/// Один вариант объекта налогообложения внутри карточки УСН/АУСН
/// (Доходы / Доходы − расходы), соответствует конкретному [TaxMode].
class TaxRegimeObject {
  final TaxMode mode;
  final String label;
  final String labelCompact;

  const TaxRegimeObject({
    required this.mode,
    required this.label,
    String? labelCompact,
  }) : labelCompact = labelCompact ?? label;
}

enum TaxRegimeRateTone { green, orange }

class TaxRegimeItem {
  final String id;
  // Ровно одно из двух: [mode] — режим без выбора объекта, или [objects] —
  // семья (УСН/АУСН) с выбором объекта внутри карточки.
  final TaxMode? mode;
  final List<TaxRegimeObject>? objects;

  final String name;
  final String rate;
  final String rateCompact;
  final TaxRegimeRateTone rateTone;
  final String who;
  final String description;
  final List<String> facts;
  final List<String> factsCompact;
  // Официальная страница ФНС по этому режиму — проверено вручную (см.
  // docs/research_ausn_psn_regions.md за контекст по ПСН/АУСН). У ФНС нет
  // единой страницы "ОСНО" — режим состоит из нескольких налогов, ссылка
  // ведёт на НДФЛ, именно его считает приложение для ИП на ОСНО.
  final String moreUrl;

  const TaxRegimeItem({
    required this.id,
    this.mode,
    this.objects,
    required this.name,
    required this.rate,
    String? rateCompact,
    required this.rateTone,
    required this.who,
    required this.description,
    required this.facts,
    List<String>? factsCompact,
    required this.moreUrl,
  }) : rateCompact = rateCompact ?? rate,
       factsCompact = factsCompact ?? facts,
       assert(
         (mode == null) != (objects == null),
         'TaxRegimeItem должен иметь либо mode, либо objects — не оба и не ни одного',
       );
}

class TaxRegimeSection {
  final String title;
  final List<TaxRegimeItem> items;
  const TaxRegimeSection({required this.title, required this.items});
}

const _fnsBase = 'https://www.nalog.gov.ru/rn77/taxation/taxes';

const List<TaxRegimeSection> taxRegimeSections = [
  TaxRegimeSection(
    title: 'Самозанятость',
    items: [
      TaxRegimeItem(
        id: 'npd',
        mode: TaxMode.npd,
        name: 'НПД',
        rate: '4–6%',
        rateTone: TaxRegimeRateTone.green,
        who: 'самозанятые и ИП',
        description:
            'Самый простой режим для тех, кто работает на себя без '
            'сотрудников — фрилансеры, репетиторы, мастера. '
            'Регистрируетесь в приложении «Мой налог» за один день, без '
            'визита в налоговую. Платите только с реально полученного '
            'дохода: 4%, если платит физлицо, и 6%, если платит компания '
            'или ИП — если в месяце дохода не было, налога тоже не будет. '
            'Не нужно вести бухгалтерию, сдавать декларации и покупать '
            'кассу — чек на каждую продажу приложение формирует само '
            '(ст. 4, 6, 8 422-ФЗ).',
        facts: [
          'Доход до 2,4 млн ₽/год',
          'Без сотрудников',
          'Вычет 10 000 ₽ новичкам',
        ],
        moreUrl: 'https://www.nalog.gov.ru/rn77/taxation/princtax/',
      ),
    ],
  ),
  TaxRegimeSection(
    title: 'Режимы для ИП',
    items: [
      TaxRegimeItem(
        id: 'usn',
        objects: [
          TaxRegimeObject(mode: TaxMode.usn6, label: 'Доходы · 6%'),
          TaxRegimeObject(
            mode: TaxMode.usn15,
            label: 'Доходы — расходы · 15%',
            labelCompact: 'Дох. — расх. · 15%',
          ),
        ],
        name: 'УСН',
        rate: '6% или 15%',
        rateTone: TaxRegimeRateTone.green,
        who: 'только ИП',
        description:
            'Самый популярный режим для ИП: вместо нескольких сложных '
            'налогов (НДФЛ, НДС, налог на имущество) платите один. Два '
            'варианта объекта — выбрать нужно один: «Доходы» — 6% от '
            'всего заработанного, без учёта расходов (выгодно, если '
            'расходов мало — например, услуги, IT); «Доходы минус '
            'расходы» — 15% с разницы между доходом и подтверждёнными '
            'расходами (выгодно, если расходы больше 60% выручки — '
            'например, торговля). Декларация — раз в год, но сам налог '
            'платится каждый квартал авансом (ст. 346.13, 346.21 НК РФ).',
        facts: [
          'Доход до 450 млн ₽/год',
          'До 130 сотрудников',
          'Декларация раз в год',
        ],
        moreUrl: '$_fnsBase/usn/',
      ),
      TaxRegimeItem(
        id: 'ausn',
        objects: [
          TaxRegimeObject(mode: TaxMode.ausn8, label: 'Доходы · 8%'),
          TaxRegimeObject(
            mode: TaxMode.ausn20,
            label: 'Доходы — расходы · 20%',
            labelCompact: 'Дох. — расх. · 20%',
          ),
        ],
        name: 'АУСН',
        rate: '8% или 20%',
        rateTone: TaxRegimeRateTone.green,
        who: 'только ИП',
        description:
            'Экспериментальный «максимально упрощённый» вариант УСН — '
            'сама налоговая считает налог по данным банковского счёта и '
            'онлайн-кассы, декларацию сдавать не нужно, а фиксированных '
            'страховых взносов «за себя» на этом режиме вообще нет. '
            'Ставки чуть выше обычной УСН (8% вместо 6%, 20% вместо '
            '15%) — плата за меньшую бумажную работу. Подходит только '
            'совсем небольшому бизнесу и только в тех регионах, где '
            'местные власти ввели режим отдельным законом — уточните '
            'регион на экране выше, чтобы не выбрать то, чего у вас нет '
            '(ст. 1, 3 17-ФЗ).',
        facts: ['Доход до 60 млн ₽/год', 'До 5 сотрудников'],
        moreUrl: 'https://www.nalog.gov.ru/rn77/taxation/taxes/autotax_system/',
      ),
      TaxRegimeItem(
        id: 'psn',
        mode: TaxMode.psn,
        name: 'ПСН',
        rate: 'патент',
        rateTone: TaxRegimeRateTone.green,
        who: 'только ИП',
        description:
            'Похоже на «абонемент» на налоги: платите заранее '
            'фиксированную сумму (патент) на срок от месяца до года — и '
            'всё, сколько бы вы реально ни заработали, доплачивать не '
            'нужно, пока не превышен лимит по доходу. Стоимость патента '
            'устанавливают власти региона для каждого вида '
            'деятельности отдельно — она не зависит от вашей реальной '
            'выручки. Подходит для розницы, услуг, мастерских, но список '
            'разрешённых видов деятельности ограничен и различается по '
            'регионам (ст. 346.43, 346.51 НК РФ).',
        facts: [
          'Доход до 60 млн ₽/год',
          'До 15 сотрудников',
          'Не для всех видов деятельности',
        ],
        // На mobile-эталоне третий факт не показан.
        factsCompact: ['Доход до 60 млн ₽/год', 'До 15 сотрудников'],
        moreUrl: 'https://www.nalog.gov.ru/rn77/taxation/taxes/patent/',
      ),
      TaxRegimeItem(
        id: 'eshn',
        mode: TaxMode.eshn,
        name: 'ЕСХН',
        rate: '6% с прибыли',
        rateTone: TaxRegimeRateTone.green,
        who: 'только ИП',
        description:
            'Специальный режим только для тех, у кого не менее 70% '
            'дохода — от сельского хозяйства: выращивание, переработка '
            'и продажа собственной продукции. Платите 6% с разницы '
            'между доходами и расходами — почти как УСН «Доходы минус '
            'расходы», только ставка ниже. Отчитываться нужно не '
            'поквартально, а дважды в год: аванс за полугодие — до 28 '
            'июля, итог за год — до 28 марта следующего года '
            '(ст. 346.2, 346.8, 346.9 НК РФ).',
        facts: ['Доля сельхоздохода ≥ 70%'],
        moreUrl: '$_fnsBase/eshn/',
      ),
      TaxRegimeItem(
        id: 'osno',
        mode: TaxMode.osno,
        name: 'ОСНО',
        rate: 'НДФЛ 13–22% + НДС',
        rateCompact: 'НДФЛ + НДС',
        rateTone: TaxRegimeRateTone.orange,
        who: 'только ИП',
        description:
            'Режим «по умолчанию» — на нём оказываются все, кто не '
            'выбрал ничего другого при регистрации, и все, кто превысил '
            'лимиты спецрежимов. Самый сложный: нужно платить НДФЛ по '
            'прогрессивной шкале (от 13% и выше при доходе свыше 2,4 '
            'млн ₽/год) и отдельно НДС (обычно 22%), вести полноценный '
            'учёт доходов и расходов. Плюс — нет ограничений по доходу '
            'и числу сотрудников, и с вами охотнее работают крупные '
            'компании — плательщики НДС, которым нужен вычет '
            '(ст. 224, 164 НК РФ).',
        facts: ['Без лимитов', 'НДС 22%', 'Больше всего отчетности'],
        moreUrl: 'https://www.nalog.gov.ru/rn77/taxation/taxes/ndfl/',
      ),
    ],
  ),
];

List<TaxRegimeItem> get taxRegimeItems =>
    taxRegimeSections.expand((s) => s.items).toList(growable: false);

/// Находит карточку и индекс объекта (0, если карточка без [objects])
/// для заданного [TaxMode] — используется контроллером, чтобы
/// предзаполнить выбор из уже сохранённого режима.
({TaxRegimeItem item, int objIndex})? findTaxRegimeItemFor(TaxMode mode) {
  for (final item in taxRegimeItems) {
    if (item.mode == mode) return (item: item, objIndex: 0);
    final objects = item.objects;
    if (objects != null) {
      final idx = objects.indexWhere((o) => o.mode == mode);
      if (idx != -1) return (item: item, objIndex: idx);
    }
  }
  return null;
}
