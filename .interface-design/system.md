# AI-Финансист — дизайн-система (актуальное состояние кода)

Источник — фактический код `lib/core/theme`, `lib/screens`, `lib/widgets`, `lib/features`. Не "хотелки", а то, что реально реализовано и работает. Обновлять при изменении токенов/раскладки, чтобы файл не расходился с реальностью.

## 0. Продуктовый контекст

- **Кто:** ИП и самозанятые в РФ, не бухгалтеры — считают налог сами.
- **Что делают:** подключают банк / загружают выписку → видят налог к уплате и срок → платят вовремя.
- **Ощущение (направление "Clean Mint"):** белый/бежевый холст, единственный зелёный акцент, рыжий — только для предупреждений и срочности, никогда не для основных действий. Суммы — моно-шрифтом, "как в бухгалтерской книге".
- **Платформа:** один Flutter-код на телефон и веб (Chrome). `ThemeMode.light` — единственная тема, тёмной нет.

---

## 1. Токены

### 1.1 Цвет (`lib/core/theme/app_colors.dart`)

Обновлено в «Этап 1» светлого редизайна (`.claude/prompt_claude_code_redesign_light.md`) — поверхности стали белее/теплее, предупреждающий цвет ярче (тёплый оранжевый вместо терракота). **Зелёная семья (`accent`/`accentDark`/`accentMid`/`accentLight`/`accentSoft`) сознательно оставлена без изменений** по явному запросу — редизайн трогал только поверхности, текст, дивайдеры и warning-цвет.

| Токен | HEX | Назначение |
|---|---|---|
| `background` | `#FDFCF9` | Фон экрана (тёплый белый, было `#EFECE3` бежевый) |
| `surface` | `#FFFFFF` | Карточки, sheets, sidebar/bottom nav |
| `surfaceAlt` | `#F4EEE1` | Чипы, инпуты, трек тумблера |
| `surfaceRail` | `#F6F3EA` | Внешняя канва (редко используется отдельно от background) |
| `accent` | `#1F7A4F` | Единственный primary-акцент: кнопки, активные состояния, положительные суммы (не менялся) |
| `accentDark/Mid/Light` | `#145C3A` / `#26925C` / `#37A96E` | Только стопы `heroGradient` (не менялся) |
| `accentSoft` (алиас `accentSubtle`) | `#E3F1E7` | Фон иконок/чипов/сегментов на акценте (не менялся) |
| `warning` (алиас `negative`) | `#E8834A` | Расход, риск, срочность — **никогда** для primary-действий (было `#C1591F` терракот) |
| `warningSoft` / `warningBorder` / `warningText` | `#FBEEE3` / `#F0CDAE` / `#A85A28` | Заливка/бордер/текст предупреждающих баннеров |
| `warningLight` | `#F3BD91` | Светлый акцент для расходных столбцов графика |
| `textPrimary` | `#1B241F` | Основной текст |
| `textSecondary` | `#6E7A72` | Вторичный текст |
| `textTertiary` | `#92988D` | Метаданные, даты, счётчики |
| `onAccent` | `#FFFFFF` | Текст/иконки на сплошной accent-заливке (кнопки, активные сегменты) |
| `onGradient` + `onGradientAlpha(a)` | white, лесенка альфы 0.7–0.95 / 0.12–0.22 | Текст/плашки поверх `heroGradient` |
| `divider` / `dividerSoft` | `#EAE4D6` / `#F2EFE4` | Бордер карточек / разделители строк списка |
| `heroGradient` | `LinearGradient([accentDark→accentMid(55%)→accentLight])`, 135° | Только hero-карточка налога (не менялся) |

**Критично:** `textPrimary` — тёмный. Использовать его как цвет текста/иконки НА сплошной `accent`-заливке или на `heroGradient` — баг низкого контраста (тёмный на зелёном). На accent-заливке — только `onAccent`; на градиенте — только `onGradient`/`onGradientAlpha()`.

### 1.1.1 Новые файлы токенов — `app_gradients.dart`, `app_shadows.dart`

- **`AppGradients`** (`lib/core/theme/app_gradients.dart`): `primary` (hero/CTA — переиспользует `accentDark→accent`, тот же зелёный, что и `heroGradient`, не новый), `chart` (зелёный → прозрачный, для баров/линий графика), `beigeSection` (тёплая бежевая заливка сгруппированных секций), `warm` (рыжий градиент — **только** бейджи расходов/предупреждений, никогда кнопки/крупные поверхности).
- **`AppShadows`** (`lib/core/theme/app_shadows.dart`): `card` — единственная тень в проекте (`textPrimary` @ 6% alpha, blur 24, offset (0,8)). Правило: `elevation` виджетов всегда `0`; тень — либо `AppShadows.card`, либо бордер `AppColors.divider` для «тихих» карточек, никогда оба сразу. Реально подключена пока только к `MetricChip` (доход/расход на дашборде, рядом с hero-карточкой — единственная карточка, которой намеренно дана бо́льшая визуальная весомость через тень вместо бордера); все остальные карточки — border-only, это тоже корректный выбор по тому же правилу, не пробел.
- **Радиусы**: после Этапа 4 ни одного «сырого» `BorderRadius.circular(N)` не осталось вне `AppRadius.*` — кроме `monthly_chart.dart` (легенда-квадратик 10×10, радиус 3) — намеренное исключение: это микро-декор ниже гранулярности шкалы (`sm`=12 уже сделал бы 10px-квадрат идеальным кругом, заметно другой формой), не архитектурная карточка/кнопка/чип, которые шкала призвана унифицировать.

### 1.2 Типографика (`lib/core/theme/app_text_styles.dart`)

UI-текст — **Inter**, денежные суммы — **JetBrains Mono** (tabular figures).

| Стиль | Размер/вес | Шрифт |
|---|---|---|
| `displayLarge` | 36/700 | Inter |
| `headlineMedium` | 22/800 | Inter |
| `titleMedium` | 15/600 | Inter |
| `bodyMedium` | 14/400, textSecondary | Inter |
| `labelSmall` | 11/700, ls 0.8, ВЕРХНИЙ РЕГИСТР | Inter |
| `amount` | 38/800, ls −0.5 | JetBrains Mono |
| `amountSmall` | 15/700 | JetBrains Mono |

Локальные `.copyWith(fontSize: X)` поверх базовых стилей — обычная практика (напр. 18px заголовок AppBar, 13.5px кнопки).

### 1.3 Spacing / Radius (`lib/core/theme/app_theme.dart`)

`AppSpacing`: `sp4·sp8·sp12·sp16·sp18·sp20·sp24·sp32·sp48`.
`AppRadius` (обновлено в Этапе 1 светлого редизайна): `sm=12` (чипы/иконки) · `md=18` (карточки/инпуты/кнопки) · `lg=24` (hero-карточка, sheets) · `xl=28` (модальные контейнеры) · `full=999` (пилюли).

### 1.4 Глубина

Сдвиг цвета поверхности + тонкий бордер `divider`, теней нет (`CardTheme.elevation=0`, кнопки `elevation:0`). Бордер — не декоративный, а структурный сигнал (карточки, поля).

### 1.5 Breakpoints и адаптивность (`AppBreakpoints`, `lib/widgets/responsive_page.dart`)

Приложение одинаково работает на телефоне и в вебе на ноутбуке — раскладка адаптивная, не растянутая мобильная страница:

- `< 900px` (`AppBreakpoints.desktop`) — телефон: нижний `NavigationBar` (4 таба, подписи видны), контент во всю ширину.
- `≥ 900px` — desktop: `MainScreen` переключается на **боковую навигацию** (`_Sidebar`, 232px, тот же фон `background`, что и канва — не "плашка админки", тонкий бордер справа, активный пункт — `accentSoft` пилюля). Контент каждого экрана оборачивается в `ResponsivePage(maxWidth: …)` — центрируется в рабочей ширине (560–640px для форм/списков, не растягивается на весь монитор).
- `≥ 1180px` (`AppBreakpoints.wideDesktop`) — только Dashboard: настоящая **2-колоночная** раскладка (`_WideBody`), а не просто поля по краям. Левая колонка 620px — hero-карточка, действия, график. Правая 360px — совет + последние операции. Итоговая ширина (620+32+360=1012px) тоже центрируется.

Экраны без основного шелла (TaxMode, банковский флоу) на desktop центрируются через `ResponsivePage` (480px для BankConsent/BankLoading — калиброваны под узкую композицию; 560px для форм/списков). **Onboarding — исключение**: на desktop (`≥900px`) он не центрируется, а раскрывается в полноэкранный сплит-скрин (`_OnboardingPage.isWide` в `onboarding.dart`) — левая панель `_IllustrationZone` (кольца+иконка, `large: true`, крупнее мобильной) на всю высоту, правая — текст/точки/CTA, отцентрированные внутри с `maxWidth: 440`, обе панели растянуты `CrossAxisAlignment.stretch` до краёв окна. Ниже `900px` — прежний мобильный вертикальный `Stack` (PageView + нижняя панель точки/CTA), без изменений.

**Правило на будущее:** любой новый экран с `Scaffold(body: ...)` должен оборачивать своё скроллируемое содержимое в `ResponsivePage` с разумным `maxWidth`, если экран заходит под `MainScreen`/самостоятельный `Scaffold` — иначе на широком окне он будет растянут на весь монитор.

---

## 2. Информационная архитектура

```
Onboarding (3 слайда Clean Mint: тег-пилюля, кольца+floating-чипы, CTA)
  → TaxRegimeSelectScreen(isInitialSetup: true) (выбор Самозанятый/ИП +
    режим — тот же экран, что и "Изменить" в настройках, см. §5.4)
    → MainScreen (desktop: sidebar / mobile: bottom nav, 4 вкладки)
        ├─ Dashboard ("Главная") — 1 или 2 колонки (см. §1.5)
        │    ├─→ BankSelectionScreen → BankConsentScreen → BankLoadingScreen ─┐
        │    ├─→ AddTransactionScreen                                        │
        │    └─→ PeriodDetailScreen ("Все операции")                        │
        ├─ History ("История") ──→ PeriodDetailScreen                       │
        ├─ Statements ("Выписки")                                           │
        └─ Settings ("Настройки")                                           │
             ├─→ ProfileScreen (аватар/имя/телефон/email/регион/           │
             │     вид деятельности/ИНН/ОГРНИП + выход из аккаунта)         │
             ├─→ TaxRegimeScreen → Select/Details                           │
             └─→ ConnectedBanksScreen ←────────────────────────────────────┘

Onboarding → LoginScreen ('/login', Firebase: email/телефон-SMS/Google) →
'/tax-mode' — форма входа теперь обязательный шаг между онбордингом и
выбором режима (см. LoginScreen._goToTaxMode, onboarding.dart._goToTaxMode).
```

### 5.4 Один экран выбора режима на оба сценария

Раньше `'/tax-mode'` был отдельным самодельным экраном (`TaxModeScreen`) —
внешне похожим, но не идентичным экрану "Изменить режим" в настройках
(`TaxRegimeSelectScreen`). Файл `tax_mode_screen.dart` удалён; маршрут
`/tax-mode` в `main.dart` теперь рендерит `TaxRegimeSelectScreen(isInitialSetup: true)`
— **тот же самый** виджет (тот же `_RegimePicker`, тот же `TaxStatusToggle`,
тот же `TaxRegimeDetailsScreen` для режимов с доп.настройками), что и кнопка
"Изменить" на `TaxRegimeScreen`. `isInitialSetup` меняет только то, что
происходит НЕ визуально: заголовок AppBar ("Выберите налоговый режим" вместо
"Изменить режим"), скрытую кнопку "назад" (`automaticallyImplyLeading:
false` — возвращаться некуда, позади экран логина) и финальную навигацию
(`pushReplacementNamed('/main')` вместо `pop()` — тут нет предыдущего
"экрана-обзора", в который нужно вернуться).

Роуты — `lib/main.dart`. Bottom nav подписи **видны** (`alwaysShow`) — в отличие от прежней тёмной версии, где они были скрыты.

**Паттерн: градиентный profile-header.** `heroGradient` — единственный градиент в приложении (см. §1) — теперь используется в двух местах: hero-карточка дашборда И шапка `ProfileScreen` (`_ProfileHeader` в `profile_screen.dart`). Структура: `Stack` с `Container(height: 148, gradient: heroGradient, borderRadius: vertical bottom lg)` снизу и `Positioned(bottom: -avatarSize/2)` с круглым аватаром (белая рамка 4px) поверх границы — классический "перекрывающий аватар" паттерн. После Stack — `SizedBox(height: avatarSize/2 + sp12)`, чтобы контент под аватаром не наезжал. AppBar на этом экране прозрачный (`extendBodyBehindAppBar: true`, `iconTheme: onAccent`), т.к. сидит поверх градиента.

---

## 3. Ключевые компоненты (значения на будущее)

- **TaxSummaryCard** — hero, `heroGradient`, `lg` радиус, `sp20` паддинг. Весь текст внутри — `onGradient`/`onGradientAlpha()`, никогда `textPrimary`. Риск-баннеры и НДФЛ-заметка **вынесены наружу** карточки (в `_Warnings`/`_NdflScaleNote` на dashboard.dart), не внутрь.
- **MetricChip** — `surface` + `divider`-бордер, `md` радиус, up/down-иконка цвета значения.
- **WarningBanner** (`lib/widgets/warning_banner.dart`) — общий виджет для риск-баннеров: `warningSoft` фон, `warningBorder` бордер, опциональный chevron+onTap.
- **TransactionTile** — круглая иконка 36px, `accentSoft`/`warningSoft`/`surfaceAlt` фон по типу; `unknown` (не размечено) — `warning` иконка + левый бордер 3px + тап открывает bottom sheet классификации.
- **FilledButton/ElevatedButton** — `accent` заливка, текст/иконка **обязательно** `onAccent` (тема это форсирует централизованно в `app_theme.dart`).
- **Sidebar/_SidebarItem** (desktop-шелл) — активный пункт `accentSoft` фон + `accent` текст/иконка, неактивный — `textSecondary`/`textPrimary`.
- **Сегментированные контролы/чипы-фильтры** (Этап 2/3 редизайна — «беж никогда не интерактивный»): неактивное состояние — `surface` + бордер `divider`, НЕ `surfaceAlt`. Затрагивает `_ObjectOption`/`_IpRegimeList` (tax_regime_screen.dart), `_Chip` (period_detail_screen.dart), `_CategorySelector` (add_transaction_screen.dart), `_MethodToggle` (login_screen.dart), `TaxStatusToggle` (widgets/). Активное состояние по-прежнему `accent`/`accentSubtle`.
- **TransactionTile** — доход/расход раскрашены симметрично везде (иконка, фон иконки, сумма): доход `accent`/`accentSoft`/`positive`, расход `warning`/`warningSoft`/`negative` (было: расход — нейтральный `textPrimary`/`surfaceAlt`, без рыжего).
- **MonthlyChart** — бар дохода закрашен `AppGradients.chart` (зелёный → прозрачный), а не плоским `positive`.
- **Onboarding `_CtaButton`** — единственная кнопка в приложении с градиентной заливкой (`AppGradients.primary`, через `Material`+`InkWell` поверх `Container` — `FilledButton` градиент не поддерживает). Остальные кнопки приложения — по-прежнему плоский `accent` через глобальную `FilledButtonTheme`, чтобы не плодить вторые градиенты в кадре.

---

## 4. Состояния

| Тип | Где | Как |
|---|---|---|
| Пустое | History, Statements | Иконка + заголовок + подпись + CTA по центру |
| Загрузка | Dashboard, Statements | `CircularProgressIndicator` accent |
| Требует внимания | TransactionTile `unknown` | warning-иконка + левый бордер + tap-to-classify |
| Риск/лимит | `WarningBanner` под hero-карточкой | `warningSoft`/`warningBorder`, иконка warning |
| Срочный дедлайн | `_PaymentProgress` на hero | прогресс-бар и текст пересвечиваются, когда ≤7 дней |
| Успех | BankLoadingScreen | full-bleed `accent` фон, галочка на `onAccent`-плашке, авто-переход |

---

## 5. Известные особенности / решения

1. Единственный градиент (`heroGradient`) — намеренное исключение из правила "один акцент"; используется только для hero-карточки налога.
2. Банковский флоу (`bank_selection/consent/loading_screen.dart`) полностью на дизайн-системе — прежнее расхождение (светлые захардкоженные экраны на фоне тёмного приложения) устранено при переходе на светлую тему.
3. Desktop не является отдельным дизайном — та же цветовая/типографическая система, разница только в шелле (sidebar вместо bottom nav) и максимальной ширине контента (см. §1.5).

---

*Обновлено при переходе на светлую тему "Clean Mint" и внедрении адаптивной desktop/laptop-раскладки (sidebar-навигация, `ResponsivePage`, 2-колоночный дашборд на широких окнах).*
