---
name: flutter-onboarding-green-orange
description: >
  Дизайн-система онбординга AI-Финансист (зелёно-оранжевая, светлая) для всех
  платформ: iOS, Android, Web/desktop. Загружать перед любой задачей, которая
  касается онбординга — экранов, виджетов, темы, анимаций или адаптивности.
  Источник истины по композиции — HTML-прототипы в docs/design/.
---

# Онбординг AI-Финансист — зелёно-оранжевая система

## Когда использовать этот скилл

Загружать перед:
- созданием или правкой любого файла в `lib/features/onboarding/`
- изменением цветов, типографики, анимаций онбординга
- задачами про адаптивность / веб-версию / «выглядит плохо на …»

## Источник истины

Пиксельные эталоны лежат в `docs/design/`:
- `onboarding_mobile_concept.html` — iPhone/Android (390×844)
- `onboarding_desktop_concept.html` — Web ≥ 900px

При любом расхождении между этим файлом и прототипом — прототип прав.
Открой его в браузере и сверяй композицию, цвета, тайминги.

---

## 1. Принципы

1. **Один брейкпоинт, две композиции.** `< 900` — вертикальная мобильная
   (сцена сверху 54%, контент снизу), `≥ 900` — горизонтальная
   (сцена 55% слева, контент 45% справа). Никаких «растянутых» мобильных
   layout на десктопе.
2. **Сцена — это продукт, а не иконка.** В сцене живут настоящие UI-карточки
   приложения (налог, совет ИИ, банки), а не абстрактные пиктограммы.
3. **Зелёный главный, оранжевый вторичный.** Оранжевый только для: дохода,
   ИИ-акцентов, рисков, стрелки в CTA, хвоста градиентов. Если оранжевого
   стало больше зелёного — это ошибка.
4. **На мобильном меньше.** Максимум 2 карточки в сцене на шаг (на десктопе
   3), меньше текста в карточках, ни одного элемента, требующего hover.
5. **Layout не прыгает.** Высота блока описания фиксируется под самый длинный
   текст; смена шага не должна сдвигать CTA и индикаторы.

---

## 2. Токены

Все цвета — только в `core/theme/app_colors.dart`. Литералов в виджетах нет.

```dart
// Онбординг, светлая зелёно-оранжевая тема
static const Color onbBg         = Color(0xFFFAF8F2); // тёплый кремовый фон
static const Color onbInk        = Color(0xFF1C2B23); // основной текст
static const Color onbInkSoft    = Color(0xFF5C6B61); // вторичный текст
static const Color onbGreen      = Color(0xFF2F6B4F); // главный акцент
static const Color onbGreenDeep  = Color(0xFF1E4A36); // hover/pressed, градиенты
static const Color onbGreenSoft  = Color(0xFFE4EEE6); // фон зелёных чипов
static const Color onbOrange     = Color(0xFFE07A3F); // вторичный акцент
static const Color onbOrangeText = Color(0xFFB85C24); // текст оранжевых чипов
static const Color onbOrangeSoft = Color(0xFFF9E8DB); // фон оранжевых чипов
static const Color onbCard       = Color(0xFFFFFFFF);
static const Color onbLine       = Color(0xFFE6E2D6); // разделители, kbd

// Орб сцены
static const RadialGradient onbOrb = RadialGradient(
  center: Alignment(-0.36, -0.40),
  colors: [Color(0xFF7FB894), Color(0xFF3E7A5B), Color(0xFFE58B4E)],
  stops: [0.0, 0.42, 1.0],
);

// Прогресс, активная точка-индикатор, линии степпера
static const LinearGradient onbProgress = LinearGradient(
  colors: [Color(0xFF2F6B4F), Color(0xFFE07A3F)],
);

// Фон сцены
static const LinearGradient onbSceneBg = LinearGradient(
  begin: Alignment.topLeft, end: Alignment.bottomRight, // ~160–165°
  colors: [Color(0xFFEDF3EC), Color(0xFFF3EEE2)],
);
```

Единственные разрешённые тени:

```dart
// карточки сцены
BoxShadow(color: onbGreenDeep.withOpacity(.24),
  blurRadius: 44, spreadRadius: -18, offset: Offset(0, 18)); // mobile
BoxShadow(color: onbGreenDeep.withOpacity(.22),
  blurRadius: 60, spreadRadius: -24, offset: Offset(0, 24)); // desktop
// CTA
BoxShadow(color: onbGreenDeep.withOpacity(.5),
  blurRadius: 28, spreadRadius: -12, offset: Offset(0, 14));
```

### Типографика — Manrope

| Роль              | Mobile | Desktop        | Вес | Прочее                        |
|-------------------|--------|----------------|-----|-------------------------------|
| Заголовок h1      | 34     | clamp 38–54    | 800 | ls −0.03em, height 1.05–1.08  |
| Сумма (hero)      | 24     | 30             | 800 | tabularFigures, ls −0.02em    |
| Описание          | 15     | 17             | 400 | height 1.55–1.6, onbInkSoft   |
| Текст карточки    | 13     | 14             | 400–600 | height 1.45–1.5           |
| Label карточки    | 10     | 11             | 600 | UPPERCASE, ls 0.08em          |
| Чип               | 12     | 13             | 600 |                               |
| CTA               | 16     | 16             | 700 |                               |

Радиусы: чипы/CTA/точки — pill (999), карточки — 16, сцена — 32
(на мобильном скругление только снизу: `borderRadius: vertical(bottom: 32)`),
иконки ИИ — 10–12, иконки банков — 9–10, номер шага (desktop) — 9.

Отступы — только из шкалы проекта: 4/8/12/16/24/32/48.

---

## 3. Структура кода

```
features/onboarding/
  onboarding_screen.dart           // LayoutBuilder: <900 — mobile, иначе desktop
  onboarding_mobile.dart           // Column: сцена + контент, свайп по сцене
  onboarding_desktop.dart          // Row 55/45, state currentStep
  data/onboarding_steps.dart       // тексты трёх шагов (единый источник)
  widgets/
    onboarding_scene.dart          // орб + зерно + кольца + Stack карточек
    grain_overlay.dart             // noise-PNG, softLight, opacity .35
    scene_tax_cards.dart           // карточки шага 0 (варианты mobile/desktop)
    scene_ai_cards.dart            // шаг 1
    scene_banks_cards.dart         // шаг 2
    onboarding_dots.dart           // mobile-индикатор
    onboarding_stepper.dart        // desktop-степпер 01/02/03
    onboarding_cta.dart            // пилюля с оранжевой стрелкой
    onb_chip.dart                  // green / orange / glass варианты
```

Текст шагов — только в `onboarding_steps.dart`, чтобы mobile и desktop
не разъезжались:

```dart
const onboardingSteps = [
  OnbStep(
    chip: 'Автоматический расчёт', chipOrange: false,
    title: 'Считаем налог ', accent: 'за вас',
    desc: 'Загружаем выписку из банка и сами вычисляем налог по вашей '
          'системе — УСН, НПД, ОСНО и другим.',
  ),
  OnbStep(
    chip: 'Искусственный интеллект', chipOrange: true,
    title: 'Без ', accent: 'бухгалтерии',
    desc: 'ИИ классифицирует каждую операцию, даёт советы по оптимизации '
          'и предупреждает о рисках.',
  ),
  OnbStep(
    chip: 'Банковские интеграции', chipOrange: false,
    title: 'Автоимпорт ', accent: 'операций',
    desc: 'Подключите свой банк один раз — доходы и расходы будут '
          'импортироваться автоматически, каждый день.',
  ),
];
```

---

## 4. Сцена (общая для платформ)

Слои снизу вверх:

1. Фон `onbSceneBg`.
2. **Орб**: круг с заливкой `onbOrb`, blur 2 (`ImageFiltered`), opacity .85.
   Размер: mobile 400×400, desktop 520×520. Позиция и scale зависят от шага
   (§7). Анимация смещения — 1000мс easeOutCubic.
3. **Зерно** (`grain_overlay.dart`): файловый монохромный noise-PNG 256×256
   из `assets/images/noise.png`, `BlendMode.softLight`, opacity .35,
   `IgnorePointer`. — Не делать шум шейдером/CustomPainter — PNG стабильнее
   и дешевле, особенно в Web.
4. **Кольца**: `CustomPaint`, 3 концентрические окружности, stroke 1,
   `onbGreen.withOpacity(.12)`. Радиусы от базового размера:
   mobile 110/160/215 (база 390×456), desktop 170/240/310 (база 700×640) —
   масштабировать пропорционально фактическому размеру сцены.
5. **Карточки**: `Stack`, позиции в процентах от размеров сцены через
   `LayoutBuilder` (не фиксированные пиксели — развалится на других
   диагоналях). Точные позиции и состав карточек — по эталонным прототипам.

Состав карточек на шаг:

| Шаг | Mobile (2 шт.)                          | Desktop (3 шт.)                     |
|-----|------------------------------------------|--------------------------------------|
| 0   | hero-налог, чип «↗ +241 000 ₽ за квартал» | + отдельная карточка «Доход за квартал» + glass-чип «Расчёт обновлён» |
| 1   | совет ИИ, чип риска НПД                  | + карточка «Возврат клиенту ✓»       |
| 2   | банки (2 строки), glass-чип «132 операции» | банки (3 строки) + импорт + glass  |

Hero-карта налога: прогресс-бар (высота 7 mobile / 8 desktop, фон
onbGreenSoft, заливка onbProgress) анимируется 0→64% за 1000–1100мс,
easeOutCubic, delay 350мс — при каждом входе на шаг 0.

---

## 5. Мобильная композиция (iOS + Android)

```
┌────────────────────────────┐
│  сцена  (54% высоты)      │ ← скругление 32 только снизу
│  [Пропустить] · glass-чип │    поверх сцены, top-right
│      орб + карточки       │
├────────────────────────────┤
│ чип-eyebrow                │
│ Заголовок 34/800           │
│ Описание (flex, minH)      │
│      • ●● ●  точки        │
│ [   Далее  →   ] CTA      │ ← full-width
└────────────────────────────┘
```

- Контент-паддинг: 26 по бокам, снизу `20 + safe-area inset`
  (`SafeArea(top: false)` + `viewPadding.bottom`).
- Сцена уходит под статус-бар: `SystemUiOverlayStyle.dark`
  (тёмные иконки на светлой сцене), edge-to-edge на Android
  (`SystemChrome.setEnabledSystemUIMode(edgeToEdge)`), прозрачный navbar.
- «Пропустить»: glass-чип (белый .55 + blur 8), не просто текст —
  иначе теряется на орбе.
- **Индикатор — точки, не степпер.** 7×7 pill, цвет onbLine; активная
  растягивается до 26px с градиентом onbProgress (анимация 350мс).
- **Навигация — свайп по сцене + CTA.** CTA «Далее» и горизонтальный свайп
  по сцене вызывают один и тот же переход шага (общий индекс состояния),
  анимация 400мс easeOutCubic. Никакого системного `PageView`, дающего
  горизонтальный слайд всего экрана — в прототипе меняется только контент
  внутри сцены/текста (crossfade+slide карточек), а не сам экран целиком.
- CTA full-width, высота ~56, pressed: scale .98 + onbGreenDeep.
  На тапе — `HapticFeedback.lightImpact()` (iOS и Android).
- Никаких hover-состояний; вся интерактивность — tap и swipe.

## 6. Десктопная композиция (Web ≥ 900)

```
┌ maxWidth 1280, по центру ──────────────────────────────┐
│ [₽ AI-Финансист]                        [Пропустить]  │
│ ┌ сцена 55% ───────────┐  чип-eyebrow                  │
│ │  орб + 3 карточки    │  Заголовок 38–54/800          │
│ │  radius 32           │  Описание (minHeight 82)      │
│ │                      │  01 Расчёт налога ────        │
│ │                      │  02 Советы от ИИ  ──          │
│ │                      │  03 Импорт из банков          │
│ └──────────────────────┘  [ Далее → ]  ⌨ ← →          │
└──────────────────────────────────────────────────────────┘
```

- Степпер вместо точек: строки 01/02/03, кликабельные, `MouseRegion` +
  `SystemMouseCursors.click`, hover-фон `onbGreen` 6% opacity.
  Состояния: active (номер onbGreen/белый, линия scaleX 0→1 за 500мс),
  done (номер onbOrangeSoft/onbOrangeText), idle (onbGreenSoft/onbInkSoft).
- CTA — компактная пилюля (не full-width), паддинг 17×34. Hover:
  onbGreenDeep, подъём 2px, стрелка +3px вправо; переходы 250мс.
- Клавиатура ←/→ обязательна (`Focus` + `onKeyEvent`), фокус виден.
- Подсказка про клавиши: kbd-стиль — белый фон, обводка onbLine,
  нижняя обводка 2px, radius 6.

---

## 7. Анимации

Использовать `flutter_animate` (уже в проекте).

Смена шага:
1. Уходящие карточки: fadeOut + slideY(+20/24px) + scale(.96), 300мс.
2. Приходящие — каскад: задержки 50/200/350мс, каждая
   `fadeIn + slideY(24→0) + scale(.96→1)`, 450–600мс, easeOutCubic.
3. Орб (1000мс easeOutCubic):
   - шаг 0: центр, scale 1
   - шаг 1: сдвиг вправо-вверх ~8%, scale 1.06
   - шаг 2: сдвиг влево-вниз ~8%, scale .96
4. Текст (чип, заголовок, описание): `AnimatedSwitcher` 250мс cross-fade.
5. Индикаторы: mobile-точка 350мс; desktop-линия 500мс.

`MediaQuery.disableAnimations == true` — все Duration.zero.

---

## 8. Чего избегать

| ❌ Нельзя | ✅ Вместо этого |
|-----------|----------------|
| Растягивать мобильный layout на desktop | Две композиции через LayoutBuilder |
| Цветовые литералы в виджетах | Только AppColors.onb* |
| Шум шейдером / feTurbulence-аналогами | noise.png + softLight |
| `Positioned` с фиксированными px в сцене | Проценты от LayoutBuilder |
| Больше 2 карточек в мобильной сцене | Ровно как в эталоне |
| Оранжевый как основной (CTA, заголовки) | Оранжевый — только акценты |
| Точки-индикаторы на desktop | Кликабельный степпер |
| Степпер / hover-эффекты на mobile | Точки + swipe + haptic |
| Разные тексты шагов в mobile/desktop | Единый onboarding_steps.dart |
| Тени кроме двух разрешённых | §2, только карточки и CTA |

---

## 9. Чек-лист приёмки

- [ ] iPhone SE (375×667): карточки не перекрывают друг друга, CTA не обрезан
- [ ] iPhone Pro Max / крупный Android: сцена не «пустеет», орб масштабируется
- [ ] Android edge-to-edge: контент не под системными жестами
- [ ] Web 1440×900: пиксельное совпадение с desktop-прототипом
- [ ] Web 900–1100: ничего не ломается на минимальной десктоп-ширине
- [ ] Свайп и кнопка «Далее» дают одинаковую анимацию
- [ ] ←/→ работают на Web; haptic на тапе CTA в мобильных сборках
- [ ] Прогресс-бар налога проигрывается при каждом входе на шаг 0
- [ ] Суммы — tabularFigures; тексты — из onboarding_steps.dart
- [ ] reduced motion — без анимаций; const-конструкторы где возможно
