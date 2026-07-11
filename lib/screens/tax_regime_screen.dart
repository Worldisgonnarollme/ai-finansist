import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/tax_mode.dart';
import '../models/tax_settings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../widgets/tax_status_toggle.dart';
import '../widgets/settings_section.dart';
import '../widgets/responsive_page.dart';
import '../main.dart';

// Экран-обзор текущего налогового режима. Два независимых действия:
// "Изменить" у карточки режима (сверху) — открывает выбор другого режима
// и сохраняет ТОЛЬКО его; "Внести изменения" (снизу) — открывает
// редактирование доп.настроек (сотрудники, дата регистрации, ставка/
// патент) и сохраняет ТОЛЬКО их. Смена режима не требует немедленного
// заполнения деталей, и наоборот — это два раздельных потока.
class TaxRegimeScreen extends StatelessWidget {
  const TaxRegimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final mode = state.taxMode;
    final settings = state.taxSettings;

    return Scaffold(
      appBar: AppBar(
        title: Text('Налоговый режим', style: AppTextStyles.headlineMedium),
      ),
      body: SafeArea(
        child: ResponsivePage(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sp16,
              AppSpacing.sp8,
              AppSpacing.sp16,
              AppSpacing.sp32,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sp16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mode.shortName,
                                style: AppTextStyles.titleXLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mode.description,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sp8),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TaxRegimeSelectScreen(),
                            ),
                          ),
                          child: const Text('Изменить'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sp16 - 2),
                    Container(height: 1, color: AppColors.dividerSoft),
                    const SizedBox(height: AppSpacing.sp12),
                    _DetailFacts(text: mode.detailedDescription),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sp24),
              if (mode == TaxMode.npd)
                const _NpdInfoCards()
              else ...[
                _RegimeInfoSection(mode: mode, settings: settings),
                const SizedBox(height: AppSpacing.sp24),
                FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaxRegimeDetailsScreen(mode: mode),
                    ),
                  ),
                  child: const Text('Внести изменения'),
                ),
                if (mode == TaxMode.ausn8 || mode == TaxMode.ausn20) ...[
                  const SizedBox(height: AppSpacing.sp24),
                  const _AusnInfoCards(),
                ],
                if (mode == TaxMode.usn6 || mode == TaxMode.usn15) ...[
                  const SizedBox(height: AppSpacing.sp24),
                  const _UsnInfoCards(),
                ],
                if (mode == TaxMode.osno) ...[
                  const SizedBox(height: AppSpacing.sp24),
                  const _OsnoInfoCards(),
                ],
                if (mode == TaxMode.psn) ...[
                  const SizedBox(height: AppSpacing.sp24),
                  const _PsnInfoCards(),
                ],
                if (mode == TaxMode.eshn) ...[
                  const SizedBox(height: AppSpacing.sp24),
                  const _EshnInfoCards(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Подробное описание режима (mode.detailedDescription) — в модели это
// одна строка из коротких фактов через ". ". Раньше выводилась одним
// плотным абзацем 11px/700 (стиль для капс-лейблов, а не для чтения) —
// нечитаемо. Разбиваем на отдельные пункты с акцентной точкой, каждый —
// обычным текстовым размером с нормальным line-height.
class _DetailFacts extends StatelessWidget {
  final String text;
  const _DetailFacts({required this.text});

  List<String> get _facts => text
      .split('. ')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .map((s) => s.endsWith('.') ? s.substring(0, s.length - 1) : s)
      .toList();

  @override
  Widget build(BuildContext context) {
    final facts = _facts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < facts.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 9, right: AppSpacing.sp8),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  facts[i],
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w400,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          if (i != facts.length - 1) const SizedBox(height: AppSpacing.sp8 - 2),
        ],
      ],
    );
  }
}

// Только для чтения: сотрудники, дата регистрации, ставка/патент —
// редактирование только через "Внести изменения" на экране-обзоре.
class _RegimeInfoSection extends StatelessWidget {
  final TaxMode mode;
  final TaxSettings settings;
  const _RegimeInfoSection({required this.mode, required this.settings});

  double get _currentRate {
    switch (mode) {
      case TaxMode.usn6:
        return settings.usn6Rate;
      case TaxMode.usn15:
        return settings.usn15Rate;
      case TaxMode.eshn:
        return settings.eshnRate;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Настройки режима',
      children: [
        SettingsRow(
          child: _InfoRow(
            label: 'Сотрудников',
            value: '${settings.employeeCount}',
          ),
        ),
        SettingsRow(
          child: _InfoRow(
            label: 'Дата регистрации ИП',
            value: settings.registrationDate == null
                ? 'Не указана'
                : DateFormat('dd.MM.yyyy').format(settings.registrationDate!),
          ),
        ),
        if (mode == TaxMode.usn6 ||
            mode == TaxMode.usn15 ||
            mode == TaxMode.eshn)
          SettingsRow(
            child: _InfoRow(
              label: 'Региональная ставка',
              value: '${_currentRate.toStringAsFixed(0)}%',
            ),
          ),
        if (mode == TaxMode.psn) ...[
          SettingsRow(
            child: _InfoRow(
              label: 'Стоимость патента',
              value: '${settings.patentAnnualCost.toStringAsFixed(0)} ₽/год',
            ),
          ),
          SettingsRow(
            child: _InfoRow(
              label: 'Дата начала патента',
              value: settings.patentStartDate == null
                  ? 'Не указана'
                  : DateFormat('dd.MM.yyyy').format(settings.patentStartDate!),
            ),
          ),
          SettingsRow(
            child: _InfoRow(
              label: 'Срок патента',
              value: '${settings.patentDurationMonths} мес.',
            ),
          ),
        ],
        if (mode == TaxMode.usn6 || mode == TaxMode.usn15)
          SettingsRow(
            child: _InfoRow(
              label: 'Остаточная стоимость ОС',
              value: '${settings.fixedAssetsValue.toStringAsFixed(0)} ₽',
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.titleMedium)),
        const SizedBox(width: AppSpacing.sp12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// Выбор статуса и системы налогообложения — отдельный экран, открывается
// кнопкой "Изменить" у карточки режима на экране-обзоре. Сохраняет ТОЛЬКО
// режим; доп.настройки редактируются отдельно (TaxRegimeDetailsScreen).
class TaxRegimeSelectScreen extends StatefulWidget {
  // true — экран открыт сразу после регистрации/входа (маршрут
  // '/tax-mode'), когда режим ещё не выбран впервые: по завершении
  // ведём не назад (pop — там экран логина, а не обзор режима), а
  // вперёд, в MainScreen. false (по умолчанию) — обычная смена уже
  // сохранённого режима из настроек, поведение как раньше (pop назад
  // на TaxRegimeScreen). Страница и весь выбор режима — те же самые в
  // обоих случаях, отличается только финальная навигация и заголовок.
  final bool isInitialSetup;
  const TaxRegimeSelectScreen({super.key, this.isInitialSetup = false});

  @override
  State<TaxRegimeSelectScreen> createState() => _TaxRegimeSelectScreenState();
}

class _TaxRegimeSelectScreenState extends State<TaxRegimeSelectScreen> {
  late TaxMode _selected;

  @override
  void initState() {
    super.initState();
    _selected = context.read<AppState>().taxMode;
  }

  void _finish() {
    if (widget.isInitialSetup) {
      Navigator.pushReplacementNamed(context, '/main');
      return;
    }
    Navigator.pop(context);
    rootMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: const Text('Режим сохранён'),
        backgroundColor: AppColors.surfaceAlt,
      ),
    );
  }

  Future<void> _continue() async {
    final appState = context.read<AppState>();

    // Режим без доп.настроек и без выбора объекта (только НПД, но он
    // обрабатывается отдельно выше) — сохраняем сразу.
    if (!_needsRegimeDetails(_selected)) {
      appState.setTaxMode(_selected);
      _finish();
      return;
    }

    // Остальные режимы — экран с доп.настройками и/или выбором объекта
    // (УСН/АУСН). Сохранение (и режима, и настроек) происходит там;
    // сюда возвращается true при успехе.
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaxRegimeDetailsScreen(mode: _selected),
      ),
    );
    if (!mounted) return;
    if (saved == true) {
      if (widget.isInitialSetup) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.isInitialSetup,
          title: Text(
            widget.isInitialSetup
                ? 'Выберите налоговый режим'
                : 'Изменить режим',
            style: AppTextStyles.headlineMedium,
          ),
        ),
        body: SafeArea(
          child: ResponsivePage(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sp16,
                      AppSpacing.sp8,
                      AppSpacing.sp16,
                      AppSpacing.sp16,
                    ),
                    children: [
                      _RegimePicker(
                        selected: _selected,
                        onChanged: (m) => setState(() => _selected = m),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sp16,
                    0,
                    AppSpacing.sp16,
                    AppSpacing.sp16,
                  ),
                  child: FilledButton(
                    onPressed: _continue,
                    child: Text(
                      _needsRegimeDetails(_selected) ? 'Далее' : 'Сохранить',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Редактирование доп.настроек режима (сотрудники, дата регистрации,
// региональная ставка/патент). Открывается двумя путями: кнопкой
// "Внести изменения" на экране-обзоре (mode = уже сохранённый режим) или
// кнопкой "Далее" при смене режима (mode = ещё не сохранённый выбор —
// сохраняем его здесь же, вместе с настройками, одним действием).
class TaxRegimeDetailsScreen extends StatefulWidget {
  final TaxMode mode;
  const TaxRegimeDetailsScreen({super.key, required this.mode});

  @override
  State<TaxRegimeDetailsScreen> createState() => _TaxRegimeDetailsScreenState();
}

class _TaxRegimeDetailsScreenState extends State<TaxRegimeDetailsScreen> {
  late TaxMode _mode;
  late TaxSettings _settings;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _settings = context.read<AppState>().taxSettings;
  }

  // Семья (объект налогообложения) для текущего _mode — null, если у
  // режима нет выбора объекта (ОСНО/ПСН/ЕСХН).
  List<TaxMode>? get _family {
    if (_mode == TaxMode.usn6 || _mode == TaxMode.usn15) {
      return const [TaxMode.usn6, TaxMode.usn15];
    }
    if (_mode == TaxMode.ausn8 || _mode == TaxMode.ausn20) {
      return const [TaxMode.ausn8, TaxMode.ausn20];
    }
    return null;
  }

  String get _familyLabel =>
      (_mode == TaxMode.usn6 || _mode == TaxMode.usn15) ? 'УСН' : 'АУСН';

  void _save() {
    final appState = context.read<AppState>();
    appState.setTaxMode(_mode);
    appState.setTaxSettings(_settings);
    FocusScope.of(context).unfocus();
    Navigator.pop(context, true);
    rootMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: const Text('Режим и настройки сохранены'),
        backgroundColor: AppColors.surfaceAlt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final family = _family;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Настройки режима', style: AppTextStyles.headlineMedium),
        ),
        body: SafeArea(
          child: ResponsivePage(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sp16,
                      AppSpacing.sp8,
                      AppSpacing.sp16,
                      AppSpacing.sp16,
                    ),
                    children: [
                      if (family != null) ...[
                        _ObjectToggle(
                          familyLabel: _familyLabel,
                          selected: _mode,
                          options: family,
                          onChanged: (m) => setState(() => _mode = m),
                        ),
                        const SizedBox(height: AppSpacing.sp24),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.sp4,
                            bottom: AppSpacing.sp16,
                          ),
                          child: Text(
                            _mode.shortName,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      // Сотрудники и дата регистрации ИП показываются для
                      // всех режимов на этом экране, включая АУСН (у нёй
                      // просто не будет полей ставки/патента — они и так
                      // условны внутри _TaxSettingsSection). Справочная
                      // информация про режим сюда НЕ добавляется — она живёт
                      // только на экране-обзоре (TaxRegimeScreen), как и для
                      // НПД/УСН.
                      _TaxSettingsSection(
                        mode: _mode,
                        settings: _settings,
                        onChanged: (v) => setState(() => _settings = v),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sp16,
                    0,
                    AppSpacing.sp16,
                    AppSpacing.sp16,
                  ),
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Переключатель объекта налогообложения (Доходы / Доходы-расходы) для
// семей УСН и АУСН — показывается сверху экрана доп.настроек режима.
class _ObjectToggle extends StatelessWidget {
  final String familyLabel;
  final TaxMode selected;
  final List<TaxMode> options;
  final ValueChanged<TaxMode> onChanged;
  const _ObjectToggle({
    required this.familyLabel,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  static String _percentOf(TaxMode m) {
    switch (m) {
      case TaxMode.usn6:
        return '6%';
      case TaxMode.usn15:
        return '15%';
      case TaxMode.ausn8:
        return '8%';
      case TaxMode.ausn20:
        return '20%';
      default:
        return '';
    }
  }

  static String _labelOf(TaxMode m) {
    switch (m) {
      case TaxMode.usn6:
      case TaxMode.ausn8:
        return 'Доходы';
      case TaxMode.usn15:
      case TaxMode.ausn20:
        return 'Доходы-расходы';
      default:
        return m.shortName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.sp4,
            bottom: AppSpacing.sp8,
          ),
          child: Text(
            'Объект $familyLabel'.toUpperCase(),
            style: AppTextStyles.labelSmall,
          ),
        ),
        Row(
          children: [
            for (final mode in options) ...[
              if (mode != options.first) const SizedBox(width: AppSpacing.sp12),
              Expanded(
                child: _ObjectOption(
                  label: _labelOf(mode),
                  percent: _percentOf(mode),
                  active: mode == selected,
                  onTap: () => onChanged(mode),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ObjectOption extends StatelessWidget {
  final String label;
  final String percent;
  final bool active;
  final VoidCallback onTap;
  const _ObjectOption({
    required this.label,
    required this.percent,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp12,
          vertical: AppSpacing.sp12,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.accentSubtle : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: active ? AppColors.accent : AppColors.divider,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: active ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sp8),
            Flexible(
              child: Text(
                '$label ($percent)',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Запрет ведущих нулей в числовом поле ───────────────────

class _NoLeadingZeroFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (text.length > 1 && text.startsWith('0')) {
      text = text.replaceFirst(RegExp(r'^0+'), '');
      if (text.isEmpty) text = '0';
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    return newValue;
  }
}

// ── Picker режима ──────────────────────────────────────────

// Двухуровневый выбор: сначала статус (Самозанятый / ИП), затем — только
// для ИП — конкретная система налогообложения. НПД доступен исключительно
// самозанятым, поэтому объединять его в один плоский список с режимами ИП
// не нужно — статус и режим это разные по смыслу решения пользователя.
//
// УСН и АУСН показаны в списке одной карточкой каждая (а не отдельно по
// объекту налогообложения) — конкретный объект (6%/15%, 8%/20%) выбирается
// отдельным переключателем на следующем экране (после кнопки "Далее").
typedef _RegimeFamily = ({
  String label,
  String description,
  List<TaxMode> members,
});

final List<_RegimeFamily> _ipFamilies = [
  (
    label: 'УСН',
    description: 'Упрощённая система — объект выбирается на следующем шаге',
    members: [TaxMode.usn6, TaxMode.usn15],
  ),
  (
    label: 'АУСН',
    description: 'Автоматизированная УСН — объект выбирается на следующем шаге',
    members: [TaxMode.ausn8, TaxMode.ausn20],
  ),
  (
    label: TaxMode.osno.shortName,
    description: TaxMode.osno.description,
    members: [TaxMode.osno],
  ),
  (
    label: TaxMode.psn.shortName,
    description: TaxMode.psn.description,
    members: [TaxMode.psn],
  ),
  (
    label: TaxMode.eshn.shortName,
    description: TaxMode.eshn.description,
    members: [TaxMode.eshn],
  ),
];

// Режим требует доп.экран (TaxRegimeDetailsScreen) если у него есть свои
// настройки (hasInsurance) ИЛИ он входит в семью с выбором объекта
// (УСН/АУСН) — там же и происходит выбор конкретной ставки.
bool _needsRegimeDetails(TaxMode mode) =>
    mode.hasInsurance || mode == TaxMode.ausn8 || mode == TaxMode.ausn20;

class _RegimePicker extends StatefulWidget {
  final TaxMode selected;
  final ValueChanged<TaxMode> onChanged;
  const _RegimePicker({required this.selected, required this.onChanged});

  @override
  State<_RegimePicker> createState() => _RegimePickerState();
}

class _RegimePickerState extends State<_RegimePicker> {
  // Запоминает последний выбранный режим ИП, чтобы при переключении
  // "ИП" → "Самозанятый" → "ИП" не сбрасывать выбор на дефолт.
  late TaxMode _lastIpMode;

  @override
  void initState() {
    super.initState();
    _lastIpMode = widget.selected == TaxMode.npd
        ? TaxMode.usn6
        : widget.selected;
  }

  @override
  void didUpdateWidget(_RegimePicker old) {
    super.didUpdateWidget(old);
    if (widget.selected != TaxMode.npd) {
      _lastIpMode = widget.selected;
    }
  }

  bool get _isSelfEmployed => widget.selected == TaxMode.npd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TaxStatusToggle(
          isSelfEmployed: _isSelfEmployed,
          onChanged: (selfEmployed) =>
              widget.onChanged(selfEmployed ? TaxMode.npd : _lastIpMode),
        ),
        // Под "Самозанятый" на экране выбора режима — без описаний и
        // справочных карточек (у НПД нет выбора системы налогообложения,
        // показывать тут нечего). Справка про НПД остаётся только на
        // экране-обзоре уже сохранённого режима (TaxRegimeScreen).
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _isSelfEmployed
              ? const SizedBox.shrink()
              : _IpRegimeList(
                  selected: widget.selected,
                  onChanged: widget.onChanged,
                ),
        ),
      ],
    );
  }
}

// Справочные карточки НПД — сотрудники, лимит дохода, сроки оплаты,
// налоги и взносы. Показываются только на экране-обзоре уже сохранённого
// режима (TaxRegimeScreen), не на экране выбора/смены режима.
final List<({IconData icon, String title, String body})> _npdInfoItems = [
  (
    icon: Icons.groups_outlined,
    title: 'Сотрудники',
    body:
        'Наём работников по трудовым договорам запрещён — '
        'ст. 4 Федерального закона № 422-ФЗ. Если нужны сотрудники, режим НПД '
        'не подходит — выберите статус ИП.',
  ),
  (
    icon: Icons.account_balance_wallet_outlined,
    title: 'Лимит дохода',
    body:
        'Максимум — 2,4 млн ₽ в год суммарно от всех заказчиков '
        '(нельзя получить 2 млн ₽ от одного и 1 млн ₽ от другого — '
        'лимит всё равно будет превышен).\n\n'
        'Если лимит по доходам превысит самозанятый без статуса ИП. В этом случае физлицо потеряет право на уплату НПД до конца календарного года. На все доходы сверх лимита нужно будет уплатить НДФЛ по ставке 13%. В следующем календарном году физическое лицо снова может стать плательщиком НПД. Второй вариант — зарегистрироваться в качестве ИП и использовать УСН, ЕСХН или ПСН до конца года. \n\n'
        'Если лимит по доходам превысит самозанятый ИП. У ИП есть 20 календарных дней, чтобы подать заявление в ФНС на смену налогового режима. Если за это время не подать заявление, то до конца года будет применяться общая система налогообложения. В следующем году можно опять перейти на НПД. Для этого нужно будет снова подать заявление о переходе на НПД и уведомление о прекращении применения старого налогового режима.\n\n'
        'Для исполнителей-ИП также действует лимит на один платёж — '
        'не более 100 000 ₽ по одному договору (в валюте — '
        'эквивалент по курсу, Указание Банка России № 5348-У). '
        'Превышение лимита выплаты — штраф по ст. 15.1 КоАП: '
        'для ИП — 4 000–5 000 ₽, для юрлиц — 40 000–50 000 ₽.\n\n'
        'Безналичные переводы — без ограничений по сумме, лимиты '
        'законом не установлены.',
  ),
  (
    icon: Icons.event_outlined,
    title: 'Когда нужно оплатить налог',
    body:
        'НПД платится раз в месяц. ФНС считает сумму по итогам '
        'месяца и присылает уведомление в приложение «Мой налог» '
        'не позднее 12-го числа следующего месяца. Оплатить нужно '
        'до 28-го числа того же месяца (ст. 11 ФЗ № 422-ФЗ, п. 3) — '
        'период оплаты: с 12 по 28 число.',
  ),
  (
    icon: Icons.local_offer_outlined,
    title: 'Налоговый вычет',
    body:
        'Разовая субсидия 10 000 ₽ от государства автоматически снижает '
        'ставку НПД (4%→3% с доходов от физлиц, 6%→4% с доходов от юрлиц '
        'и ИП) до полного исчерпания — приложение «Мой налог» считает и '
        'списывает её само, без заявлений, а неизрасходованный остаток '
        'не сгорает и переносится на следующий год.',
  ),
  (
    icon: Icons.receipt_long_outlined,
    title: 'Налоги и взносы',
    body:
        'Самозанятые не платят НДФЛ с доходов от своей '
        'деятельности. ИП на НПД дополнительно освобождены от '
        'фиксированных страховых взносов и почти всего НДС '
        '(кроме НДС при ввозе товаров на территорию РФ).\n\n'
        'Ставка зависит от плательщика (ст. 10 ФЗ № 422): 4% — '
        'доход от физлиц, 6% — доход от ИП и организаций. Ставки '
        'зафиксированы законом и не изменятся до 2029 года '
        '(п. 2, 3 ст. 1 ФЗ № 422).',
  ),
];

class _NpdInfoCards extends StatelessWidget {
  const _NpdInfoCards();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in _npdInfoItems) ...[
          _InfoCard(icon: item.icon, title: item.title, body: item.body),
          if (item != _npdInfoItems.last)
            const SizedBox(height: AppSpacing.sp12),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp8 - 2),
                // Пункты внутри body разделены "\n" в данных (см. списки
                // ниже) — раньше выводились стилем для капс-лейблов
                // (11px/700), что для юридически важных фактов нечитаемо.
                // Обычный читаемый размер + межстрочный интервал.
                Text(
                  body,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w400,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Справочные карточки УСН — сотрудники, лимит дохода и НДС, сроки уплаты,
// страховые взносы ИП, остаточная стоимость ОС. Показываются на
// экране-обзоре режима ниже кнопки "Внести изменения" (только для УСН).
final List<({IconData icon, String title, String body})> _usnInfoItems = [
  (
    icon: Icons.groups_outlined,
    title: 'Сотрудники',
    body:
        'Лимит — 130 человек в среднем за отчётный период (штатные '
        'сотрудники, внешние совместители и исполнители по договорам '
        'ГПХ, кроме самозанятых). Повышенные ставки при штате '
        '101–130 человек отменены с 2025 года — ставка не меняется '
        'вплоть до превышения лимита. При превышении — переход на '
        'ОСНО (ст. 346.13 НК РФ).',
  ),
  (
    icon: Icons.receipt_long_outlined,
    title: 'Лимит дохода и НДС',
    body:
        'До 20 млн ₽ в год — НДС не платится.\n'
        'От 20 до 272,5 млн ₽ — льготный НДС 5% без права на вычеты.\n'
        'От 272,5 до 490,5 млн ₽ — льготный НДС 7% без права на вычеты.\n'
        'Свыше 490,5 млн ₽ — полная потеря права на УСН, автоматический '
        'переход на ОСНО с начала квартала, в котором произошло '
        'превышение.',
  ),
  (
    icon: Icons.event_outlined,
    title: 'Сроки уплаты и отчётности',
    body:
        'Авансовые платежи — до 28 апреля, 28 июля и 28 октября '
        '(ст. 346.21 НК РФ, п. 7).\nИтоговый налог за год для ИП — до '
        '28 апреля следующего года, декларация — до 25 апреля '
        'следующего года.',
  ),
  (
    icon: Icons.account_balance_wallet_outlined,
    title: 'Страховые взносы (ИП)',
    body:
        'Платятся независимо от дохода и ведения деятельности: '
        'фиксированная сумма 57 390 ₽ — до 28 декабря текущего года, '
        'дополнительно 1% с дохода свыше 300 000 ₽ — до 1 июля '
        'следующего года.\n\n'
        'На УСН «Доходы» взносы уменьшают сам налог (не базу): без '
        'сотрудников — до 100%, с сотрудниками — не более 50% '
        '(ст. 346.21 НК РФ, п. 3.1). На УСН «Доходы минус расходы» '
        'взносы включаются в состав расходов (ст. 346.16 НК РФ).',
  ),
  (
    icon: Icons.inventory_2_outlined,
    title: 'Основные средства',
    body:
        'Остаточная стоимость основных средств не должна превышать '
        '218 млн ₽ — при превышении право на УСН утрачивается '
        '(ст. 346.12 НК РФ).',
  ),
];

class _UsnInfoCards extends StatelessWidget {
  const _UsnInfoCards();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in _usnInfoItems) ...[
          _InfoCard(icon: item.icon, title: item.title, body: item.body),
          if (item != _usnInfoItems.last)
            const SizedBox(height: AppSpacing.sp12),
        ],
      ],
    );
  }
}

// Справочные карточки АУСН — ставки, страховые взносы, сроки уплаты и
// отчётности, лимиты. Показываются на экране сохранения режима (после
// выбора объекта АУСН и до нажатия "Сохранить").
final List<({IconData icon, String title, String body})> _ausnInfoItems = [
  (
    icon: Icons.percent_rounded,
    title: 'Налоговые ставки',
    body:
        'Немного выше, чем на обычной УСН:\n'
        'Объект «Доходы» — 8% (на УСН — 6%).\n'
        'Объект «Доходы минус расходы» — 20% (на УСН — 15%), при этом '
        'действует минимальный налог 3% от всех доходов, если по итогам '
        'года бизнес сработал в убыток или в ноль.',
  ),
  (
    icon: Icons.account_balance_wallet_outlined,
    title: 'Страховые взносы — главный плюс',
    body:
        'Взносы «за себя» (для ИП) — 0 ₽: фиксированные пенсионные и '
        'медицинские взносы (57 390 ₽ на обычной УСН) платить не нужно.\n'
        'Взносы за работников — тариф 0% на пенсионное, медицинское и '
        'социальное страхование.\n'
        'Взнос на травматизм — единственный, что остаётся: фиксированно '
        '2 959 ₽ в год за весь штат (не зависит от числа сотрудников и '
        'их зарплат), выплачивается ежемесячно равными долями по '
        '246,58 ₽.',
  ),
  (
    icon: Icons.event_outlined,
    title: 'Сроки уплаты и отчётность',
    body:
        'Налоговый период — 1 месяц: налог считается и платится '
        'ежемесячно, а не поквартально. Срок уплаты — до 25-го числа '
        'следующего месяца (ст. 12 ФЗ № 17-ФЗ, п. 2; ФНС сама '
        'присылает уведомление с суммой не позднее 15-го числа).\n'
        'Взнос на травматизм — до 15-го числа следующего месяца.\n'
        'Декларации нет — учёт (бухгалтерская отчётность для ООО, КУДиР '
        'для ИП) ведётся автоматически в личном кабинете АУСН ФНС.',
  ),
  (
    icon: Icons.rule_outlined,
    title: 'Лимиты и ограничения',
    body:
        'Режим подходит не всем — критерии отбора строгие:\n'
        'Доход — не более 60 млн ₽ с начала календарного года.\n'
        'Сотрудники — средняя численность не более 5 человек, только '
        'резиденты РФ, зарплату нельзя выплачивать наличными.',
  ),
];

class _AusnInfoCards extends StatelessWidget {
  const _AusnInfoCards();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in _ausnInfoItems) ...[
          _InfoCard(icon: item.icon, title: item.title, body: item.body),
          if (item != _ausnInfoItems.last)
            const SizedBox(height: AppSpacing.sp12),
        ],
      ],
    );
  }
}

// Справочные карточки ОСНО — НДФЛ (прогрессивная шкала), НДС, страховые
// взносы за сотрудников, лимиты. Показываются на экране-обзоре режима,
// под блоком "Настройки режима" (только для ОСНО).
final List<({IconData icon, String title, String body})> _osnoInfoItems = [
  (
    icon: Icons.percent_rounded,
    title: 'НДФЛ вместо налога на прибыль',
    body:
        'ИП на ОСНО платят не налог на прибыль, а НДФЛ по '
        'прогрессивной пятиступенчатой шкале (ст. 224 НК РФ):\n'
        '13% — доход до 2,4 млн ₽ в год.\n'
        '15% — доход от 2,4 до 5 млн ₽.\n'
        '18% — доход от 5 до 20 млн ₽.\n'
        '20% — доход от 20 до 50 млн ₽.\n'
        '22% — доход свыше 50 млн ₽.\n\n'
        'Авансы — до 28 апреля, 28 июля и 28 октября (ст. 227 НК РФ, '
        'п. 6). Итоговый налог за год — до 15 июля следующего года '
        '(п. 8), декларация 3-НДФЛ — до 30 апреля.',
  ),
  (
    icon: Icons.receipt_long_outlined,
    title: 'НДС',
    body:
        'Основная ставка — 22%, применяется к большинству товаров, '
        'работ и услуг. Льготные ставки: 10% (детские товары, лекарства, '
        'базовые продукты) и 0% (экспорт, международные перевозки).\n\n'
        'Налог за квартал делится на 3 равные доли и платится до '
        '28-го числа каждого из трёх месяцев следующего квартала '
        '(ст. 174 НК РФ, п. 1). Декларация — строго в электронном виде, '
        'до 25-го числа.',
  ),
  (
    icon: Icons.groups_outlined,
    title: 'Страховые взносы за сотрудников',
    body:
        'Тарифы привязаны к Единой предельной базе (ЕПБ), которая '
        'ежегодно индексируется: в пределах лимита ЕПБ — 30% от '
        'зарплаты работника, свыше лимита — 15,1%. Для малого и '
        'среднего бизнеса (МСП) — 15% с выплат, превышающих 1 МРОТ '
        'в месяц. Срок уплаты — ежемесячно до 28-го числа следующего '
        'месяца.\n\nПриложение считает только фиксированные взносы ИП '
        '«за себя» — взносы за нанятых сотрудников нужно считать '
        'отдельно от их фактических зарплат.',
  ),
  (
    icon: Icons.all_inclusive_rounded,
    title: 'Лимиты и ограничения',
    body:
        'На ОСНО ограничений нет: доход не ограничен, численность '
        'сотрудников любая, разрешены все виды деятельности — включая '
        'банковскую и страховую деятельность, производство любых '
        'подакцизных товаров.',
  ),
];

class _OsnoInfoCards extends StatelessWidget {
  const _OsnoInfoCards();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in _osnoInfoItems) ...[
          _InfoCard(icon: item.icon, title: item.title, body: item.body),
          if (item != _osnoInfoItems.last)
            const SizedBox(height: AppSpacing.sp12),
        ],
      ],
    );
  }
}

// Справочные карточки ПСН — лимит дохода (с графиком снижения по годам),
// сотрудники, виды деятельности, стоимость патента и сроки уплаты,
// уменьшение на взносы, доп. 1%-взнос. Показываются на экране-обзоре
// режима, под блоком "Настройки режима" (только для ПСН).
final List<({IconData icon, String title, String body})> _psnInfoItems = [
  (
    icon: Icons.account_balance_wallet_outlined,
    title: 'Лимит дохода',
    body:
        'Самое болезненное изменение 2026 года: новый лимит — '
        '20 млн ₽ в год (было 60 млн ₽). Если совмещаете патент с УСН, '
        'доходы по обоим режимам суммируются — как только общий оборот '
        'с начала года превысит 20 млн ₽, право на патент теряется.\n\n'
        'План снижения лимита долгосрочный: в 2027 году — 15 млн ₽, '
        'с 2028 года — 10 млн ₽.',
  ),
  (
    icon: Icons.groups_outlined,
    title: 'Сотрудники',
    body:
        'Средняя численность — не более 15 человек. Считаются все '
        'работники по всем патентам ИП, если их несколько. При '
        'совмещении ПСН и УСН на патенте может быть занято не более '
        '15 человек, хотя общий штат с УСН может быть больше '
        '(ст. 346.43 НК РФ).',
  ),
  (
    icon: Icons.storefront_outlined,
    title: 'Виды деятельности',
    body:
        'Патент разрешён только ИП (ООО применять не может) и только '
        'для видов деятельности из региональных списков.\n\n'
        'Оставили: розничную торговлю и грузоперевозки.\n'
        'С 2026 года запретили: охранные услуги, уличные патрули и '
        'вахтёров; торговлю маркированными товарами (лекарства, обувь, '
        'шубы); работу на маркетплейсах покупными товарами.',
  ),
  (
    icon: Icons.event_outlined,
    title: 'Стоимость патента и сроки уплаты',
    body:
        'Налог — это фиксированная стоимость патента (6% от '
        'потенциально возможного годового дохода, который устанавливают '
        'власти региона). Реальный заработок на стоимость не влияет.\n\n'
        'Если патент выдан на срок меньше 12 месяцев, стоимость '
        'считается пропорционально: потенциальный годовой доход делится '
        'на 12 и умножается на число месяцев действия патента '
        '(ст. 346.51 НК РФ, п. 1) — точную сумму по своим датам можно '
        'сверить на калькуляторе ФНС.\n\n'
        'Патент до 6 месяцев — единый платёж в любой день до окончания '
        'срока действия. Патент от 6 до 12 месяцев — двумя платежами: '
        '1/3 стоимости — в течение 90 календарных дней с даты начала, '
        'оставшиеся 2/3 — до 28 декабря текущего года.',
  ),
  (
    icon: Icons.local_offer_outlined,
    title: 'Уменьшение стоимости патента на взносы',
    body:
        'ИП без сотрудников может уменьшить стоимость патента до 0% '
        '(полностью списать за счёт фиксированных взносов за себя). '
        'ИП с сотрудниками — максимум на 50% (за счёт взносов за себя '
        'и за работников) — ст. 346.51 НК РФ, п. 1.2. Для уменьшения '
        'нужно отправить в налоговую уведомление об уменьшении налога '
        'на сумму взносов.',
  ),
  (
    icon: Icons.percent_rounded,
    title: 'Доп. 1%-взнос — по потенциальному доходу',
    body:
        'Поскольку реальный доход налоговую не интересует, '
        'дополнительный 1% взносов «за себя» считается по-особому: '
        'базой служит потенциально возможный доход, прописанный в '
        'патенте, а не сумма, поступившая на счёт. Если потенциальный '
        'доход по патенту больше 300 000 ₽, платится 1% с суммы '
        'превышения — приложение уже учитывает это при расчёте.',
  ),
];

class _PsnInfoCards extends StatelessWidget {
  const _PsnInfoCards();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in _psnInfoItems) ...[
          _InfoCard(icon: item.icon, title: item.title, body: item.body),
          if (item != _psnInfoItems.last)
            const SizedBox(height: AppSpacing.sp12),
        ],
      ],
    );
  }
}

// Справочные карточки ЕСХН — ставка, кто может применять, НДС, сроки
// уплаты. Показываются на экране-обзоре режима, под блоком "Настройки
// режима" (только для ЕСХН).
final List<({IconData icon, String title, String body})> _eshnInfoItems = [
  (
    icon: Icons.percent_rounded,
    title: 'Ставка',
    body:
        '6% от (доходы − расходы). Регионы вправе снижать ставку — '
        'вплоть до 0% для отдельных категорий налогоплательщиков или '
        'видов продукции (ст. 346.8 НК РФ).',
  ),
  (
    icon: Icons.agriculture_outlined,
    title: 'Кто может применять',
    body:
        'ИП и ООО, у которых доля дохода от сельскохозяйственной '
        'деятельности (производство, переработка и реализация '
        'сельхозпродукции) составляет не менее 70% от общего дохода '
        '(ст. 346.2 НК РФ). Приложение не проверяет это условие '
        'автоматически — оно не определяется по банковской выписке.',
  ),
  (
    icon: Icons.receipt_long_outlined,
    title: 'НДС',
    body:
        'Освобождение действует, если доход не превышает 60 млн ₽ '
        'в год (ст. 145 НК РФ). При утрате освобождения — 10% (основная '
        'ставка для большинства сельхозпродукции), 0% при экспорте, '
        '22% (реформа 2026) — для прочих операций, не связанных '
        'напрямую с сельхозпроизводством (например, сдача техники в '
        'аренду). Платится как на ОСНО: за квартал тремя равными '
        'долями до 28-го числа каждого из следующих трёх месяцев.',
  ),
  (
    icon: Icons.event_outlined,
    title: 'Сроки уплаты и отчётности',
    body:
        'Отчётность не поквартальная, а по полугодиям: уведомление '
        'об исчисленной сумме аванса — до 25 июля, сам авансовый '
        'платёж — до 28 июля. Декларация за год — до 25 марта '
        'следующего года, итоговый налог (за вычетом аванса) — '
        'до 28 марта (ст. 346.9, 346.10 НК РФ).',
  ),
];

class _EshnInfoCards extends StatelessWidget {
  const _EshnInfoCards();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in _eshnInfoItems) ...[
          _InfoCard(icon: item.icon, title: item.title, body: item.body),
          if (item != _eshnInfoItems.last)
            const SizedBox(height: AppSpacing.sp12),
        ],
      ],
    );
  }
}

// Список конкретных систем налогообложения ИП — раскрывается только при
// выбранном статусе "ИП" (анимация раскрытия — на AnimatedSize снаружи).
class _IpRegimeList extends StatelessWidget {
  final TaxMode selected;
  final ValueChanged<TaxMode> onChanged;
  const _IpRegimeList({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sp12),
      child: Column(
        children: _ipFamilies.map((family) {
          final active = family.members.contains(selected);
          return GestureDetector(
            // Если семья уже активна — сохраняем текущий выбранный объект
            // (usn6/usn15 и т.п.), иначе берём первый член семьи по
            // умолчанию (конкретика уточняется на следующем шаге).
            onTap: () => onChanged(active ? selected : family.members.first),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sp8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp16,
                  vertical: AppSpacing.sp12,
                ),
                decoration: BoxDecoration(
                  color: active ? AppColors.accentSubtle : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: active ? AppColors.accent : AppColors.divider,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            family.label,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            family.description,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (active)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Дополнительные настройки режима ──────────────────────

class _TaxSettingsSection extends StatefulWidget {
  final TaxMode mode;
  final TaxSettings settings;
  final ValueChanged<TaxSettings> onChanged;

  const _TaxSettingsSection({
    required this.mode,
    required this.settings,
    required this.onChanged,
  });

  @override
  State<_TaxSettingsSection> createState() => _TaxSettingsSectionState();
}

class _TaxSettingsSectionState extends State<_TaxSettingsSection> {
  late TextEditingController _rateCtrl;
  late TextEditingController _patentCtrl;
  late TextEditingController _employeeCtrl;
  late TextEditingController _fixedAssetsCtrl;
  late TextEditingController _patentDurationCtrl;

  @override
  void initState() {
    super.initState();
    _rateCtrl = TextEditingController(text: _currentRate.toString());
    _patentCtrl = TextEditingController(
      text: widget.settings.patentAnnualCost.toStringAsFixed(0),
    );
    _employeeCtrl = TextEditingController(
      text: widget.settings.employeeCount.toString(),
    );
    _fixedAssetsCtrl = TextEditingController(
      text: widget.settings.fixedAssetsValue.toStringAsFixed(0),
    );
    _patentDurationCtrl = TextEditingController(
      text: widget.settings.patentDurationMonths.toString(),
    );
  }

  @override
  void didUpdateWidget(_TaxSettingsSection old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      _rateCtrl.text = _currentRate.toString();
      _patentCtrl.text = widget.settings.patentAnnualCost.toStringAsFixed(0);
    }
    // Сравниваем с тем, что уже введено в поле, а не только со старым
    // значением settings: onChanged на каждое нажатие клавиши обновляет
    // settings.employeeCount и приводит к didUpdateWidget — если сбрасывать
    // controller.text при любом изменении, курсор скачет в начало поля и
    // ввести больше одной цифры не получается. Сбрасываем только тогда,
    // когда новое значение пришло НЕ из этого же поля (например, при смене
    // режима или после сохранения).
    if (old.settings.employeeCount != widget.settings.employeeCount &&
        widget.settings.employeeCount !=
            (int.tryParse(_employeeCtrl.text) ?? -1)) {
      _employeeCtrl.text = widget.settings.employeeCount.toString();
    }
    if (old.settings.fixedAssetsValue != widget.settings.fixedAssetsValue &&
        widget.settings.fixedAssetsValue !=
            (double.tryParse(_fixedAssetsCtrl.text) ?? -1)) {
      _fixedAssetsCtrl.text = widget.settings.fixedAssetsValue.toStringAsFixed(
        0,
      );
    }
    if (old.settings.patentDurationMonths !=
            widget.settings.patentDurationMonths &&
        widget.settings.patentDurationMonths !=
            (int.tryParse(_patentDurationCtrl.text) ?? -1)) {
      _patentDurationCtrl.text = widget.settings.patentDurationMonths
          .toString();
    }
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    _patentCtrl.dispose();
    _employeeCtrl.dispose();
    _fixedAssetsCtrl.dispose();
    _patentDurationCtrl.dispose();
    super.dispose();
  }

  double get _currentRate {
    switch (widget.mode) {
      case TaxMode.usn6:
        return widget.settings.usn6Rate;
      case TaxMode.usn15:
        return widget.settings.usn15Rate;
      case TaxMode.eshn:
        return widget.settings.eshnRate;
      default:
        return 0;
    }
  }

  String get _employeeLimitHint {
    switch (widget.mode) {
      case TaxMode.npd:
        return 'Запрещено (только 0) — ст. 4 422-ФЗ';
      case TaxMode.ausn8:
      case TaxMode.ausn20:
        return 'Лимит: до 5 человек — ст. 3 422-ФЗ';
      case TaxMode.psn:
        return 'Лимит: до 15 человек — ст. 346.43 НК РФ';
      case TaxMode.usn6:
      case TaxMode.usn15:
        return 'Лимит: до 130 человек — ст. 346.13 НК РФ';
      case TaxMode.osno:
      case TaxMode.eshn:
        return 'Без ограничений';
    }
  }

  bool get _employeeLimitExceeded {
    final c = widget.settings.employeeCount;
    switch (widget.mode) {
      case TaxMode.npd:
        return c > 0;
      case TaxMode.ausn8:
      case TaxMode.ausn20:
        return c > 5;
      case TaxMode.psn:
        return c > 15;
      case TaxMode.usn6:
      case TaxMode.usn15:
        return c > 130;
      default:
        return false;
    }
  }

  bool get _fixedAssetsExceeded =>
      widget.settings.fixedAssetsValue > 218_000_000;

  // _commitX — вызывается на каждое изменение текста (onChanged), чтобы
  // значение попадало в _settings сразу, а не только по Enter/уходу с
  // поля. Без этого нажатие «Сохранить» сразу после ввода (без явного
  // подтверждения поля) сохраняло бы старое значение. НЕ снимает фокус —
  // это делает только _saveX (onSubmitted/onEditingComplete), иначе поле
  // теряло бы фокус после каждого нажатия клавиши.
  void _commitRate(String val) {
    final parsed = double.tryParse(val.replaceAll(',', '.'));
    if (parsed == null) return;
    switch (widget.mode) {
      case TaxMode.usn6:
        widget.onChanged(
          widget.settings.copyWith(usn6Rate: parsed.clamp(1.0, 6.0)),
        );
      case TaxMode.usn15:
        widget.onChanged(
          widget.settings.copyWith(usn15Rate: parsed.clamp(5.0, 15.0)),
        );
      case TaxMode.eshn:
        widget.onChanged(
          widget.settings.copyWith(eshnRate: parsed.clamp(0.0, 6.0)),
        );
      default:
        break;
    }
  }

  void _saveRate(String val) {
    _commitRate(val);
    FocusScope.of(context).unfocus();
  }

  void _commitPatent(String val) {
    final parsed = double.tryParse(
      val.replaceAll(' ', '').replaceAll(',', '.'),
    );
    if (parsed == null || parsed < 0) return;
    widget.onChanged(widget.settings.copyWith(patentAnnualCost: parsed));
  }

  void _savePatent(String val) {
    _commitPatent(val);
    FocusScope.of(context).unfocus();
  }

  void _commitEmployees(String val) {
    final parsed = int.tryParse(val);
    if (parsed == null || parsed < 0) return;
    widget.onChanged(widget.settings.copyWith(employeeCount: parsed));
  }

  void _saveEmployees(String val) {
    _commitEmployees(val);
    FocusScope.of(context).unfocus();
  }

  void _commitFixedAssets(String val) {
    final parsed = double.tryParse(
      val.replaceAll(' ', '').replaceAll(',', '.'),
    );
    if (parsed == null || parsed < 0) return;
    widget.onChanged(widget.settings.copyWith(fixedAssetsValue: parsed));
  }

  void _saveFixedAssets(String val) {
    _commitFixedAssets(val);
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickRegistrationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.settings.registrationDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Дата регистрации ИП',
    );
    if (picked == null) return;
    widget.onChanged(widget.settings.copyWith(registrationDate: picked));
  }

  // Патент можно взять на срок от 1 до 12 месяцев внутри календарного
  // года — дата начала может быть и в прошлом (уже действующий патент),
  // и в ближайшем будущем (куплен заранее).
  Future<void> _pickPatentStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.settings.patentStartDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      helpText: 'Дата начала действия патента',
    );
    if (picked == null) return;
    widget.onChanged(widget.settings.copyWith(patentStartDate: picked));
  }

  void _commitPatentDuration(String val) {
    final parsed = int.tryParse(val);
    if (parsed == null || parsed < 1 || parsed > 12) return;
    widget.onChanged(widget.settings.copyWith(patentDurationMonths: parsed));
  }

  void _savePatentDuration(String val) {
    _commitPatentDuration(val);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final limitExceeded = _employeeLimitExceeded;
    return SettingsSection(
      title: 'Настройки режима',
      children: [
        // Количество сотрудников — для всех режимов
        SettingsRow(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Сотрудников', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      _employeeLimitHint,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: limitExceeded
                            ? AppColors.negative
                            : AppColors.textSecondary,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sp12),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _employeeCtrl,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _NoLeadingZeroFormatter(),
                  ],
                  style: AppTextStyles.titleMedium.copyWith(
                    color: limitExceeded
                        ? AppColors.negative
                        : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp12,
                      vertical: AppSpacing.sp12,
                    ),
                    suffix: limitExceeded
                        ? const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.negative,
                            size: 16,
                          )
                        : null,
                  ),
                  onChanged: _commitEmployees,
                  onSubmitted: _saveEmployees,
                  onEditingComplete: () => _saveEmployees(_employeeCtrl.text),
                ),
              ),
            ],
          ),
        ),
        // Пояснение про отмену системы повышенных ставок УСН (8%/20% при
        // штате 101–130 человек) — актуально с 2025 года.
        if (widget.mode == TaxMode.usn6 || widget.mode == TaxMode.usn15) ...[
          const Divider(height: 1),
          SettingsRow(
            child: Text(
              'С 2025 года повышенные ставки (8% для УСН «Доходы» и 20% '
              'для УСН «Доходы − Расходы») при штате 101–130 человек '
              'отменены. Ставка не меняется вплоть до превышения лимита '
              'в 130 сотрудников — при превышении право на УСН '
              'утрачивается (ст. 346.13 НК РФ).',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0,
                height: 1.45,
              ),
            ),
          ),
        ],
        // Дата регистрации ИП — влияет на пропорциональный расчёт
        // фиксированного страхового взноса за неполный год
        const Divider(height: 1),
        SettingsRow(
          child: GestureDetector(
            onTap: _pickRegistrationDate,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Дата регистрации ИП',
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Для пропорционального расчёта взносов за неполный год',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sp12),
                Text(
                  widget.settings.registrationDate == null
                      ? 'Не указана'
                      : DateFormat(
                          'dd.MM.yyyy',
                        ).format(widget.settings.registrationDate!),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.sp4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        // Регистрация в декабре — первый налоговый период продлевается
        // до конца СЛЕДУЮЩЕГО года (ст. 55 НК РФ, п. 2): доход, лимиты и
        // прогрессивная шкала НДФЛ считаются нарастающим итогом за оба
        // года, без обнуления 1 января. Показываем только когда это
        // реально применимо, чтобы не загромождать экран для всех.
        if (widget.settings.registrationDate?.month == 12) ...[
          const Divider(height: 1),
          SettingsRow(
            child: Text(
              'Регистрация в декабре — первый налоговый период продлён '
              'до конца следующего года (ст. 55 НК РФ, п. 2). Доход, '
              'лимиты режима и шкала НДФЛ считаются нарастающим итогом '
              'за оба года, без обнуления 1 января.',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0,
                height: 1.45,
              ),
            ),
          ),
        ],
        // Ставка налога (для УСН и ЕСХН)
        if (widget.mode == TaxMode.usn6 ||
            widget.mode == TaxMode.usn15 ||
            widget.mode == TaxMode.eshn) ...[
          const Divider(height: 1),
          SettingsRow(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Региональная ставка (%)',
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _rateHint,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sp12),
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: _rateCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                    ],
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sp12,
                        vertical: AppSpacing.sp12,
                      ),
                      suffix: Text(
                        '%',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    onChanged: _commitRate,
                    onSubmitted: _saveRate,
                    onEditingComplete: () => _saveRate(_rateCtrl.text),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Остаточная стоимость основных средств (только для УСН, лимит
        // 218 млн ₽ — ст. 346.12 НК РФ, при превышении право на УСН
        // утрачивается)
        if (widget.mode == TaxMode.usn6 || widget.mode == TaxMode.usn15) ...[
          const Divider(height: 1),
          SettingsRow(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Остаточная стоимость ОС (₽)',
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Лимит: 218 млн ₽ — ст. 346.12 НК РФ',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: _fixedAssetsExceeded
                              ? AppColors.negative
                              : AppColors.textSecondary,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sp12),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _fixedAssetsCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _NoLeadingZeroFormatter(),
                    ],
                    style: AppTextStyles.titleMedium.copyWith(
                      color: _fixedAssetsExceeded
                          ? AppColors.negative
                          : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sp12,
                        vertical: AppSpacing.sp12,
                      ),
                      suffix: _fixedAssetsExceeded
                          ? const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.negative,
                              size: 16,
                            )
                          : null,
                    ),
                    onChanged: _commitFixedAssets,
                    onSubmitted: _saveFixedAssets,
                    onEditingComplete: () =>
                        _saveFixedAssets(_fixedAssetsCtrl.text),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Стоимость патента (только для ПСН)
        if (widget.mode == TaxMode.psn) ...[
          const Divider(height: 1),
          SettingsRow(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Стоимость патента в год (₽)',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sp8),
                TextField(
                  controller: _patentCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _NoLeadingZeroFormatter(),
                  ],
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Например: 36000',
                    prefixText: '₽ ',
                  ),
                  onChanged: _commitPatent,
                  onSubmitted: _savePatent,
                  onEditingComplete: () => _savePatent(_patentCtrl.text),
                ),
                const SizedBox(height: AppSpacing.sp8),
                Text(
                  'Найти стоимость патента можно в сервисе ФНС\n«Расчёт стоимости патента» на nalog.ru',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          // Дата начала и срок патента — определяют график уплаты: единый
          // платёж (до 6 мес.) или два платежа (от 6 до 12 мес.).
          const Divider(height: 1),
          SettingsRow(
            child: GestureDetector(
              onTap: _pickPatentStartDate,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Дата начала действия патента',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Определяет график уплаты',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sp12),
                  Text(
                    widget.settings.patentStartDate == null
                        ? 'Не указана'
                        : DateFormat(
                            'dd.MM.yyyy',
                          ).format(widget.settings.patentStartDate!),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sp4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          SettingsRow(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Срок патента (месяцев)',
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'От 1 до 12 месяцев внутри календарного года',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sp12),
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: _patentDurationCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _NoLeadingZeroFormatter(),
                    ],
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sp12,
                        vertical: AppSpacing.sp12,
                      ),
                    ),
                    onChanged: _commitPatentDuration,
                    onSubmitted: _savePatentDuration,
                    onEditingComplete: () =>
                        _savePatentDuration(_patentDurationCtrl.text),
                  ),
                ),
              ],
            ),
          ),
          // Итоговая стоимость патента за фактический срок действия —
          // пропорционально числу месяцев (ст. 346.51 НК РФ, п. 1), а не
          // введённая пользователем годовая ставка напрямую.
          const Divider(height: 1),
          SettingsRow(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Итого за патент', style: AppTextStyles.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Годовая ставка ÷ 12 × срок патента '
                        '(ст. 346.51 НК РФ, п. 1)',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sp12),
                Text(
                  '${(widget.settings.patentAnnualCost / 12 * widget.settings.patentDurationMonths).toStringAsFixed(0)} ₽',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String get _rateHint {
    switch (widget.mode) {
      case TaxMode.usn6:
        return 'Стандарт — 6%, регионы могут снижать до 1%';
      case TaxMode.usn15:
        return 'Стандарт — 15%, регионы могут снижать до 5%';
      case TaxMode.eshn:
        return 'Стандарт — 6%, регионы могут снижать до 0%';
      default:
        return '';
    }
  }
}
