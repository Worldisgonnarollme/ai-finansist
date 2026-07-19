# Handoff: Dashboard (Tax Summary) — Variant 1

## Overview
Redesign of the "Главная" (Dashboard) screen for a tax-calculation app for
Russian individual entrepreneurs (ИП) and self-employed (самозанятые). Main
user action: see the tax amount due and pay on time. This package covers
**dashboard variant 1** — the gradient hero-card treatment — which the user
selected as their favorite from three explored variants.

## About the Design Files
The `Tax App Prototype.dc.html` file included for reference is an **HTML
design prototype**, not production code — it was used to explore the full
app's screens and interactions in-browser. The `lib/` folder in this handoff
is the actual deliverable: real Dart/Flutter code, written to slot into the
existing Flutter codebase described in the project's `system.md`
(`lib/core/theme`, `lib/screens`, `lib/widgets`), reusing the same file/class
names (`AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`,
`TaxSummaryCard`, `MetricChip`, etc.) so it drops in with minimal path changes.

**Important existing-app change:** the app's theme was previously
`ThemeMode.dark` only. This redesign is a **light theme** (white/beige base,
green accent, rust-orange for warnings) per the new brief. Either replace the
old dark `AppColors`/theme wholesale, or add this as a second `ThemeData` and
default to it — that's a product decision outside this handoff's scope.

## Fidelity
**High-fidelity.** Colors, type sizes/weights, spacing, radii and copy below
are final — implement pixel-for-pixel, don't restyle.

## Screens / Views — Dashboard ("Главная")

### Layout
Single scrolling column, horizontal padding 18px, top gap 8px, bottom gap
90px (clears the bottom tab bar). Vertical rhythm between sections: 14–20px.

### 1. Header row
- Left: "Здравствуйте, {имя}" — 13px / #78715F, then 6px gap, then a pill
  badge "{статус} · {режим}" (e.g. "ИП · ОСНО") — 12px/700, color #1F7A4F,
  background #E3F1E7, padding 3×10, radius 999.
- Right: 38×38 circular avatar/button, white fill, 1px #E7DFCE border,
  bell/notification icon (outline, #23261E, 18px).

### 2. TaxSummaryCard (hero, variant 1) — the centerpiece
- Container: padding 20px all sides, radius 18px, background = linear
  gradient 135°, stops `#1B6E48 → #26925C (55%) → #37A96E (100%)`.
- Label (top): period, uppercase, 11px/700, letter-spacing 0.8,
  color white @ 75% opacity. Copy: **"НАЛОГ К УПЛАТЕ · II КВАРТАЛ 2026"**.
- Amount: 10px gap below label. 38px/800, tabular/mono figures, white,
  letter-spacing -0.5. Copy: **"148 320 ₽"**.
- Deadline row: 14px gap above. Flex row, space-between. Left: "Срок оплаты:
  28 июля 2026" (13px, white @90%). Right: "19 дней" (13px/700, white @90%).
- Progress bar: 8px gap above, height 6px, radius 999, track = white @22%,
  fill = solid white, width = 30% (elapsed/total days in the payment window).
- Divider: 16px margin above+below, 1px, white @18%.
- Income/expense mini-stats row, space-between: each is a label (11.5px,
  white @70%) over a value (15px/700, mono, white). **"Доход" → "1 240 000
  ₽"**, **"Расход" → "812 500 ₽"**.
- Payment lines stack (16px gap above), each a pill: background white @12%,
  radius 10px, padding 10×12, row space-between, label 13px/500 white,
  value 13px/700 mono white:
  - **"НДФЛ (13%)" → "55 575 ₽"**
  - **"НДС к уплате" → "92 745 ₽"**
  - **"Страховые взносы" → "оплачено"**

### 3. Warning banners (below hero, 14px gap)
Two rust-colored banners, same visual style, stacked with 12px gap:
- Container: background #FBEADB, border 1px #EBCBA3, radius 12px, padding
  13×14, row with icon (18px, #C1591F) + text (12.5px/1.4, color #8A3F14).
- **Banner A (static, no chevron):** warning-triangle icon. Copy: *"Доход
  нарастающим итогом превысил 5 000 000 ₽ — с превышения НДФЛ удерживается
  по ставке 15%."*
- **Banner B (tappable, chevron-right on the right):** circle-warning icon.
  Copy: *"1 операция не размечена — уточните категорию"*. Tap → navigate to
  period detail / transaction review.

### 4. Metric chips (16px gap above)
Two equal-width cards side by side, gap 10px. White background, 1px
#E7DFCE border, radius 12px, padding 12×14.
- Each: row of [small up/down arrow icon + UPPERCASE label, 10.5px/700,
  #78715F] then 6px gap then value, 18px/700 mono.
- **"↑ ДОХОДЫ" → "1 240 000 ₽"** (green #1F7A4F, arrow up)
- **"↓ РАСХОДЫ" → "812 500 ₽"** (rust #C1591F, arrow down)

### 5. Action buttons row (14px gap above)
Two equal-width buttons, gap 10px, height ~44px (padding 12 vertical),
radius 11px:
- **Outline button:** "Подключить банк" — border 1.5px #23261E, white fill,
  text #23261E, 13.5px/600.
- **Filled button (primary):** "+ Операция" — background #1F7A4F, no
  border, text white, 13.5px/600.

### 6. Monthly chart (20px gap above)
- Section title "Доходы и расходы, 6 месяцев" — 13px/700, #23261E.
- Card: white bg, 1px #E7DFCE border, radius 14px, padding 16×14 top /
  10 bottom, height ~118px. Six month-columns, each: two bars side by side
  (7px wide, 2px gap) — income bar solid #1F7A4F, expense bar #F1C79A
  (light rust/apricot) — heights scaled to a 76px-tall plot area, then the
  month abbreviation below (10px/600, #9C9484).
  Sample data (Фев–Июл): income px-heights `[40,52,58,46,64,30]`, expense
  `[26,30,34,28,38,18]` (illustrative; wire to real monthly totals).

### 7. Advice card (14px gap above)
Background #F1E9DA, radius 12px, padding 14px. Row: 32×32 icon plate
(background #E3F1E7, radius 9, lightbulb icon 16px #1F7A4F) + 12px gap +
column [label "СОВЕТ" 10.5px/700 letter-spacing 0.8 #78715F, then 3px gap,
then body copy 13px/1.5 #23261E].
Copy: *"Перейдите на УСН 15%, чтобы снизить налоговую нагрузку — расчёт
экономии в разделе «Налоговый режим»."*

### 8. Recent transactions (20px gap above)
- Row header: "Последние операции" (13px/700, #23261E) + "Все" link
  (right-aligned, 12.5px/600, accent green, → opens full period/transaction
  list).
- List card: white bg, 1px #E7DFCE border, radius 14px, rows separated by
  1px #F1EDE1 dividers. Each row (padding 13×14, 12px gaps): 36×36 circular
  icon (background per type) + name (13.5px/600, #23261E, single line,
  ellipsis) + date below (12px, #9C9484) + amount right-aligned (13.5px/700,
  mono, colored per type).
  - **income**: icon bg #E3F1E7, up-arrow icon #1F7A4F, amount color #1F7A4F
  - **expense**: icon bg #F1E9DA, down-arrow icon #78715F, amount color
    #23261E
  - **unknown / needs review**: icon bg #FBEADB, question/alert icon
    #C1591F, amount color #C1591F (and, in the full transaction list, a 3px
    rust left border on the row)
  Sample rows: "Оплата от ООО «Вектор»" 8 июля +184 000 ₽ (income) ·
  "Аренда офиса" 5 июля −65 000 ₽ (expense) · "Перевод от физ. лица" 3 июля
  +42 500 ₽ (unknown/needs review) · "Канцелярия и расходники" 1 июля
  −8 300 ₽ (expense).

## Interactions & Behavior
- "Подключить банк" → bank-connection flow (bank list → consent → loading
  → success).
- "+ Операция" → add-transaction sheet/screen.
- Tapping the "не размечена" warning banner or "Все" → transaction list,
  ideally pre-filtered to the relevant subset (unmarked / this period).
- Progress bar and "N дней" should recolor to rust (#C1591F) when ≤7 days
  remain before the due date (matches the rest of the app's urgency
  convention) — not shown in variant 1's static mock since 19 days is
  comfortably above that threshold, but wire the threshold logic in.
- No custom animations required for the hero card itself; a gentle
  count-up on the amount (as in the original dark app) is a nice-to-have,
  not required.

## State Management
- `taxAmount`, `dueDate`, `daysLeft`, `progress` — derived from the current
  tax period calculation.
- `income`, `expense` — period totals.
- `paymentLines` — ordered list of (label, amount) pairs; varies by tax
  regime (ОСНО shown here has НДФЛ + НДС + взносы; УСН/patent/НПД would
  show a different, shorter set — reuse the same `PaymentLine` widget).
- `showNdflScaleWarning` — bool, true when cumulative annual income > 5M ₽
  (ОСНО-specific).
- `unmarkedTransactionCount` — bool/int gating the second warning banner.
- `recentTransactions` — last N transactions for the list at the bottom.

## Design Tokens
See `lib/core/theme/app_colors.dart`, `app_text_styles.dart`,
`app_spacing.dart` in this package for the full, copy-pasteable token set.
Summary:
- **Surfaces:** background #EFECE3, surface (cards) #FFFFFF, surfaceAlt
  (chips/inputs) #F1E9DA, rail/canvas #EDEAE1.
- **Accent (green, single primary):** #1F7A4F, dark stop #145C3A, mid stop
  #26925C, light stop #37A96E, soft fill #E3F1E7.
- **Warning (rust, urgency only — never a primary action color):** #C1591F,
  soft fill #FBEADB, border #EBCBA3, text-on-soft #8A3F14.
- **Text:** primary #23261E, secondary #78715F, tertiary #9C9484.
- **Divider:** #E7DFCE (card borders), #F1EDE1 (list-row separators).
- **Type:** Inter for all UI copy; JetBrains Mono for monetary figures
  (tabular). Scale: 38/800 (hero amount), 24/800 (screen titles), 18/700
  (metric-chip values), 15/700 (list amounts), 13.5/600–700 (row titles),
  13/500 (body), 12/400–600 (meta), 11/700 uppercase ls-0.8 (section
  labels).
- **Radius:** sm 8 (chips/icon plates), md 12 (standard cards/buttons),
  lg 18 (hero card), full 999 (pills/progress bars).
- **Spacing:** 4/8/12/16/18/20/24/32/48 scale (`AppSpacing`).

## Assets
No custom icon assets — all icons are Material icon-font glyphs
(`Icons.arrow_upward_rounded`, `warning_amber_rounded`, `error_outline_rounded`,
`lightbulb_outline_rounded`, `notifications_none_rounded`, etc.) or, in the
HTML prototype, hand-drawn inline SVGs of the same glyphs — swap for your
icon package of choice.

## Files
- `Tax App Prototype.dc.html` — full interactive HTML prototype (all
  screens: onboarding, tax-mode selection, dashboard ×3 variants, history,
  statements, settings, profile, tax regime + change flow, connected banks,
  bank-connect flow, add transaction). Reference for anything beyond the
  dashboard, or to compare the other two dashboard variants that were not
  chosen.
- `lib/core/theme/app_colors.dart`, `app_text_styles.dart`,
  `app_spacing.dart` — design tokens, drop-in replacements for the
  existing dark-theme files of the same name.
- `lib/widgets/tax_summary_card.dart` — the hero card (variant 1).
- `lib/widgets/payment_line.dart`, `metric_chip.dart`, `warning_banner.dart`,
  `advice_card.dart`, `transaction_tile.dart` — supporting components.
- `lib/screens/dashboard_screen.dart` — full screen assembly wiring
  everything together with the sample data used in the mock.
