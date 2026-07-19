import 'package:flutter/foundation.dart';
import '../../app_state.dart';
import '../../models/tax_mode.dart';
import 'data/tax_regimes_meta.dart';

/// Состояние экрана "Налоговый режим" — какая карточка выбрана (она же
/// раскрытая, см. RegimeAccordionCard) и какой объект УСН/АУСН внутри
/// неё выбран. Сохранение — через существующие
/// AppState.setTaxMode/setTaxSettings, формат данных не меняется
/// (§1.2 tax_regime_prompt.md).
class TaxRegimeController extends ChangeNotifier {
  final AppState appState;

  // true — экран открыт сразу после регистрации/входа (маршрут
  // '/tax-mode', см. isInitialSetup в старом TaxRegimeSelectScreen). Если
  // режим ещё ни разу не сохранялся — ничего не предвыбрано, CTA
  // задизейблена. Если уже открывали и сохраняли (hasTaxMode) — ведём
  // себя как при обычном редактировании, просто с другой финальной
  // навигацией (см. TaxRegimeScreen.finish).
  final bool isInitialSetup;

  TaxRegimeController({required this.appState, required this.isInitialSetup}) {
    if (isInitialSetup && !appState.hasTaxMode) {
      _selectedId = null;
      _objIndex = 0;
    } else {
      _initFrom(appState.taxMode);
    }
  }

  String? _selectedId;
  int _objIndex = 0;

  String? get selectedId => _selectedId;
  int get objIndex => _objIndex;

  TaxRegimeItem? get selectedItem {
    final id = _selectedId;
    if (id == null) return null;
    for (final item in taxRegimeItems) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Конкретный [TaxMode] с учётом выбранного объекта (для семей УСН/АУСН).
  TaxMode? get selectedMode {
    final item = selectedItem;
    if (item == null) return null;
    final objects = item.objects;
    return objects != null ? objects[_objIndex].mode : item.mode;
  }

  void _initFrom(TaxMode mode) {
    final found = findTaxRegimeItemFor(mode);
    if (found == null) return;
    _selectedId = found.item.id;
    _objIndex = found.objIndex;
  }

  void select(String id) {
    // Повторный тап по уже выбранной карточке — no-op, как в эталонном
    // HTML (клик там не снимает выбор и не сворачивает карточку).
    if (_selectedId == id) return;
    _selectedId = id;
    _objIndex = 0;
    notifyListeners();
  }

  void selectObject(int index) {
    if (_objIndex == index) return;
    _objIndex = index;
    notifyListeners();
  }

  // Режим требует доп.экран (TaxRegimeDetailsScreen: сотрудники, дата
  // регистрации, ставка/патент), если у него есть страховые взносы либо
  // это АУСН (сотрудники/дата регистрации нужны и там). Правило перенесено
  // из старого TaxRegimeSelectScreen._needsRegimeDetails как есть — объект
  // УСН/АУСН теперь выбирается в самой карточке, а не на этом доп.экране.
  bool needsDetails(TaxMode mode) =>
      mode.hasInsurance || mode == TaxMode.ausn8 || mode == TaxMode.ausn20;
}
