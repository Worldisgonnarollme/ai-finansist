import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../core/data/russian_regions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/region_picker.dart';
import '../../main.dart';
import '../../screens/tax_regime_screen.dart' show TaxRegimeDetailsScreen;
import 'data/tax_regimes_meta.dart';
import 'tax_regime_controller.dart';
import 'widgets/regime_accordion_card.dart';
import 'widgets/regime_bottom_bar.dart';

/// Экран выбора налогового режима — аккордеон карточек (см.
/// tax_regime_prompt.md, эталоны docs/design/tax_regime_{desktop,mobile}_v3.html).
/// Заменяет старый TaxRegimeSelectScreen целиком: выбор объекта УСН/АУСН
/// теперь внутри карточки, отдельного шага для него больше нет.
class TaxRegimeSelectScreen extends StatefulWidget {
  // true — экран открыт сразу после регистрации/входа (маршрут
  // '/tax-mode'): если режим ещё ни разу не сохранялся, ничего не
  // предвыбрано и CTA задизейблена; по завершении ведём не назад (там
  // экран логина), а вперёд, в MainScreen. false (по умолчанию) — обычная
  // смена уже сохранённого режима из настроек: текущий режим предвыбран
  // и раскрыт, по завершении — назад на TaxRegimeScreen.
  final bool isInitialSetup;
  const TaxRegimeSelectScreen({super.key, this.isInitialSetup = false});

  @override
  State<TaxRegimeSelectScreen> createState() => _TaxRegimeSelectScreenState();
}

class _TaxRegimeSelectScreenState extends State<TaxRegimeSelectScreen> {
  late final TaxRegimeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TaxRegimeController(
      appState: context.read<AppState>(),
      isInitialSetup: widget.isInitialSetup,
    )..addListener(_onControllerChanged);
  }

  void _onControllerChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
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

  Future<void> _save() async {
    final mode = _controller.selectedMode;
    if (mode == null) return;
    final appState = context.read<AppState>();

    // Режим без доп.настроек (только НПД) — сохраняем сразу. Остальные —
    // экран с доп.настройками (сотрудники, дата регистрации, ставка/
    // патент), сохранение (и режима, и настроек) происходит там; сюда
    // возвращается true при успехе. Объект УСН/АУСН уже выбран в карточке
    // выше — на доп.экране он больше не переключается.
    if (!_controller.needsDetails(mode)) {
      appState.setTaxMode(mode);
      _finish();
      return;
    }

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaxRegimeDetailsScreen(mode: mode)),
    );
    if (!mounted) return;
    if (saved == true) _finish();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.onbBg,
        // bottom: false — нижний safe-area инсет учитывает сама
        // RegimeBottomBar (см. её compact-ветку), иначе на iPhone с
        // home-индикатором отступ снизу задвоился бы.
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < AppBreakpoints.desktop;
              return Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: compact
                          ? const EdgeInsets.fromLTRB(20, 0, 20, 130)
                          : EdgeInsets.fromLTRB(
                              24,
                              40,
                              24,
                              140,
                            ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: _Content(
                            compact: compact,
                            showBack: !widget.isInitialSetup,
                            controller: _controller,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: RegimeBottomBar(
                      pickedLabel: _pickedLabel,
                      ctaLabel: _ctaLabel,
                      enabled: _controller.selectedMode != null,
                      onPressed: _save,
                      compact: compact,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String get _pickedLabel {
    final item = _controller.selectedItem;
    if (item == null) return 'Режим не выбран';
    final objects = item.objects;
    final suffix = objects != null ? ' · ${objects[_controller.objIndex].label}' : '';
    return 'Выбрано: ${item.name}$suffix';
  }

  String get _ctaLabel {
    final item = _controller.selectedItem;
    return item == null ? 'Сохранить' : 'Сохранить ${item.name}';
  }
}

class _Content extends StatelessWidget {
  final bool compact;
  final bool showBack;
  final TaxRegimeController controller;

  const _Content({
    required this.compact,
    required this.showBack,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final region = context.watch<AppState>().region;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compact)
          _MobileHeader(showBack: showBack)
        else
          _DesktopHeader(showBack: showBack),
        SizedBox(height: compact ? AppSpacing.sp16 : AppSpacing.sp24 + 4),
        _RegionRow(region: region, compact: compact),
        SizedBox(height: compact ? AppSpacing.sp16 : AppSpacing.sp24 + 4),
        for (final section in taxRegimeSections) ...[
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sp4, bottom: AppSpacing.sp8 + 2),
            child: Text(
              section.title.toUpperCase(),
              style: AppTextStyles.settingsGroupTitle,
            ),
          ),
          for (final item in section.items) ...[
            RegimeAccordionCard(
              item: item,
              selected: controller.selectedId == item.id,
              objIndex: controller.objIndex,
              onObjectChanged: controller.selectObject,
              onSelect: () => controller.select(item.id),
              compact: compact,
              unavailableNote: item.id == 'ausn' && !isAusnAvailableInRegion(region)
                  ? 'АУСН не введена в регионе «$region»'
                  : null,
            ),
            SizedBox(height: compact ? AppSpacing.sp8 + 2 : AppSpacing.sp12),
          ],
          SizedBox(height: compact ? AppSpacing.sp8 : AppSpacing.sp12 + 2),
        ],
      ],
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  final bool showBack;
  const _DesktopHeader({required this.showBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBack) ...[
          _BackButton(onTap: () => Navigator.maybePop(context)),
          const SizedBox(width: AppSpacing.sp12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Налоговый режим', style: AppTextStyles.taxRegimeH1),
              const SizedBox(height: 4),
              Text(
                'Выберите свой — от него зависит формула расчёта налога',
                style: AppTextStyles.taxRegimeSub,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileHeader extends StatelessWidget {
  final bool showBack;
  const _MobileHeader({required this.showBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBack)
                _BackButton(onTap: () => Navigator.maybePop(context))
              else
                const SizedBox(width: 38),
              const SizedBox(width: AppSpacing.sp12),
              Text(
                'Налоговый режим',
                style: AppTextStyles.taxRegimeH1.copyWith(fontSize: 22),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 50, top: 2),
            child: Text(
              'От него зависит формула расчёта налога',
              style: AppTextStyles.taxRegimeSub.copyWith(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.onbCard,
          border: Border.all(color: AppColors.onbLine),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.onbInk),
      ),
    );
  }
}

// Регион влияет на доступность режимов (АУСН введена не во всех регионах —
// см. core/data/russian_regions.dart) и на региональные ставки/лимиты
// патента, поэтому стоит вверху экрана, до списка режимов.
class _RegionRow extends StatelessWidget {
  final String region;
  final bool compact;
  const _RegionRow({required this.region, required this.compact});

  Future<void> _pick(BuildContext context) async {
    final picked = await showRegionPicker(context, current: region.isEmpty ? null : region);
    if (picked != null && context.mounted) {
      context.read<AppState>().setRegion(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sp16 : AppSpacing.sp20,
          vertical: compact ? AppSpacing.sp12 : AppSpacing.sp12 + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.onbCard,
          borderRadius: BorderRadius.circular(compact ? 14 : 16),
          border: Border.all(color: AppColors.onbLine),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: compact ? 18 : 20,
              color: AppColors.onbGreen,
            ),
            SizedBox(width: compact ? AppSpacing.sp8 + 2 : AppSpacing.sp12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Регион регистрации',
                    style: (compact
                            ? AppTextStyles.taxRegimeWho.copyWith(fontSize: 10.5)
                            : AppTextStyles.taxRegimeWho)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    region.isEmpty ? 'Не выбран' : region,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: compact
                        ? AppTextStyles.taxRegimeCardName.copyWith(fontSize: 14.5)
                        : AppTextStyles.taxRegimeCardName.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.onbInkSoft),
          ],
        ),
      ),
    );
  }
}
