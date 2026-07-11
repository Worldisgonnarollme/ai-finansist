---
name: flutter-ui-ai-finansist
description: >
  Visual design and UI guidance for the AI-Финансист Flutter app.
  Use before any widget, screen, or theming task to avoid generic Material
  defaults and produce a distinctive, professional fintech look.
---

# Flutter UI — AI-Финансист

## When to use this skill

Load this skill before:
- Creating or editing any screen (`*_screen.dart`)
- Creating or refactoring any widget (`*_widget.dart`, `*_card.dart`)
- Changing colors, typography, spacing, or theme
- Adding new UI components (charts, cards, lists, dialogs)

For the full, always-current token reference and IA diagram, see
`.interface-design/system.md` — this file is the quick-start summary; that
one is the source of truth kept in sync with the actual code.

---

## Product identity

**What it is:** A tax assistant for self-employed Russians / ИП (НПД, УСН,
АУСН, ОСНО, ПСН, ЕСХН).
**Who uses it:** Freelancers and sole proprietors — not accountants, not
corporations.
**Emotional job:** Make tax anxiety feel manageable and under control.
**Design direction:** "Clean Mint" — light, warm-white fintech. Green is the
only primary accent; warm orange is reserved for expenses/warnings, never
for primary actions. Like a smart accountant friend, not a government portal.

---

## Design principles

### 1. Never use out-of-the-box Material defaults
Default Flutter widgets (blue AppBar, white cards with grey Material shadows,
stock `ListTile`) make the app look unfinished. Every surface must have a
deliberate color, radius, and border/shadow decision.

### 2. One accent, used with restraint
Green (`AppColors.accent`) is the only primary accent — buttons, active
states, positive amounts. If everything is accented, nothing is.

### 3. Data should breathe
Financial figures need space. Don't crowd numbers. Use generous vertical
padding around any amount or percentage — at least 16px above and below.

### 4. Hierarchy through weight, not color
Use font weight to establish hierarchy (800 for display/headline, 700 for
emphasis/labels/buttons, 500 for titles, 400 for body — Manrope has no 600,
so it never appears). Avoid making everything a different color to
compensate for weak typographic structure.

### 5. Empty states are invitations
Every screen that can be empty (transaction list, history) must have a calm,
helpful empty state — icon + one-line explanation + action button. Never show
a blank white screen.

### 6. Белый доминирует, беж группирует, зелёный действует, рыжий предупреждает
70%+ of any screen is white (`AppColors.surface`) or warm-white
(`AppColors.background`). `surfaceAlt` (beige) groups *static* content
(info cards, advice blocks) — it is never the fill of a pressable
button/chip/segment in its *selected-off* state (those go white + `divider`
border instead). Green gradient (`AppGradients.primary`) — at most one
large element per screen. Orange (`AppColors.warning`/`negative`)
— expense sums, warning badges/icons, destructive-action outlines only;
never a button fill or a large surface.

---

## Token system

All tokens live in `lib/core/theme/` — never a raw `Color(0xFF...)` or
`Colors.*` outside those files, with two narrow, deliberate exceptions:
`Colors.transparent` for AppBar/Material backgrounds (there's no
"transparent" design token to alias it to), and the bank brand colors in
`lib/models/bank.dart` (`kSupportedBanks` — Т-Банк yellow, Sber green, Alfa
red, VTB blue, Raiffeisen yellow, Gazprombank blue). Those are real
third-party brand marks, not app UI colors — never move them into
`AppColors` or swap them for a design token.

### Colors (`app_colors.dart`)

```dart
// Surfaces
static const Color background   = Color(0xFFFDFCF9); // warm white canvas
static const Color surface      = Color(0xFFFFFFFF); // cards, sheets, nav
static const Color surfaceAlt   = Color(0xFFF4EEE1); // static grouping only
static const Color surfaceRail  = Color(0xFFF6F3EA); // outer canvas / rail

// Accent — green, the ONLY primary accent
static const Color accent       = Color(0xFF1F7A4F);
static const Color accentDark   = Color(0xFF145C3A); // gradient dark stop
static const Color accentMid    = Color(0xFF26925C); // gradient mid stop
static const Color accentLight  = Color(0xFF37A96E); // gradient light stop
static const Color accentSoft   = Color(0xFFE3F1E7); // icon/chip bg on accent

// Warning / expenses — warm orange, NEVER a primary action fill
static const Color warning      = Color(0xFFE8834A); // = negative
static const Color warningSoft  = Color(0xFFFBEEE3); // banner/badge fill
static const Color warningBorder= Color(0xFFF0CDAE);
static const Color warningText  = Color(0xFFA85A28);

// Text
static const Color textPrimary   = Color(0xFF1B241F);
static const Color textSecondary = Color(0xFF6E7A72);
static const Color textTertiary  = Color(0xFF92988D);
static const Color onAccent      = Color(0xFFFFFFFF); // text on solid accent
static const Color onGradient    = Color(0xFFFFFFFF); // text on gradients

// Dividers
static const Color divider     = Color(0xFFEAE4D6);
static const Color dividerSoft = Color(0xFFF2EFE4);

// Semantic aliases
static const Color positive = accent;   // income, gains
static const Color negative = warning;  // expense, risk (warm orange, not red)
```

Opacity ladder for text/fills painted **on** the gradient hero card — use
`AppColors.onGradientAlpha(x)` rather than a new `withValues(alpha:)` literal:
`onGradientPrimary` (0.95, amount/headline) · `onGradientMuted` (0.75,
secondary copy) · `onGradientFaint` (0.7, labels) · `fillOnGradient12/18/22`
(pill/progress-track fills on the gradient).

### Gradients (`app_gradients.dart`)

```dart
AppGradients.primary      // hero card, onboarding CTA/illustration — green, 3-stop
AppGradients.chart        // green → transparent, chart bars/lines
AppGradients.beigeSection // warm beige section fill (grouping)
AppGradients.warm         // orange — badges/warnings ONLY, never buttons
```

`AppGradients.primary` is the **single** green gradient in the project.
`AppColors.heroGradient` is a `@Deprecated` alias to it, kept only for
call sites that haven't been migrated — never write new code against it,
and never introduce a second/third green gradient variant.

### Shadows (`app_shadows.dart`)

```dart
AppShadows.card     // the ONLY generic card shadow
AppShadows.glow     // green glow under large gradient CTAs (onboarding, login)
AppShadows.glowSoft // lighter green glow for accent-bordered cards
```

**Rule:** `elevation` is always `0` (Material's default grey drop-shadow is
banned). A white card gets **either** `AppShadows.card` (prominent cards,
e.g. dashboard `MetricChip`) **or** a `divider` border (quiet/list-row
cards) — never both on the same card. `glow`/`glowSoft` are a separate,
deliberate primitive for green decorative glow under gradient elements —
not a violation of "one card shadow." These three are the only `BoxShadow`s
in the project; a new one goes in `app_shadows.dart`, never inline.

### Typography (`app_text_styles.dart`)

Manrope for UI text (400/500/700/800 only — Manrope has no 600, so
`FontWeight.w600` never appears anywhere in the app), JetBrains Mono
(tabular figures) for money amounts. 16 named styles, largest to smallest:

`displayHero` (42/700, onboarding headline) · `displayLarge` (36/700) ·
`headlineMedium` (22/800) · `titleXLarge` (20/800, section headers) ·
`screenTitle` (18/800, AppBar/page titles) · `titleMedium` (19/500) ·
`titleSmall` (15/500) · `bodyMedium` (16/400, textSecondary) · `bodySmall`
(13/400, textSecondary — the most-used body size) · `caption` (12/400,
textSecondary) · `captionBold` (12/700) · `labelSmall` (11/700, uppercase,
letterSpacing 0.8) · `overline` (10/700, smallest text — chart axis
labels, tiny badges) · `amount` (38/800, mono) · `amountSmall` (17/700,
mono) · `amountTiny` (13/700, mono — small tabular amounts in tiles/chips).

**Rule:** a bare `fontSize:` literal outside `app_text_styles.dart` is
banned. Need a size that doesn't exist? Add a named style there first, or
(only for a size that occurs exactly once in the whole app) extend an
existing style with `.copyWith(fontSize: …)` locally.

### Spacing (`AppSpacing` in `app_theme.dart`)

```dart
sp4 · sp8 · sp12 · sp16 · sp18 · sp20 · sp24 · sp32 · sp48
```

### Border radius (`AppRadius` in `app_theme.dart`)

```dart
sm = 12   // chips, tags, small icon plates
md = 18   // standard cards, inputs, buttons
lg = 24   // hero card, bottom sheets
xl = 28   // modal containers
full = 999 // pills, progress bars, dots (Flutter auto-clamps on small boxes)
```

Never a raw numeric radius outside these five values — if a shape must be
fully round (a pill/dot/progress-bar), use `full`: Flutter clamps it to
half the shortest side automatically, so it's always safe even on tiny
elements.

---

## Component patterns

### Tax summary card (dashboard hero) — the signature element

```dart
Container(
  padding: const EdgeInsets.all(AppSpacing.sp20),
  decoration: BoxDecoration(
    gradient: AppGradients.primary,
    borderRadius: BorderRadius.circular(AppRadius.lg),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Налог к уплате', style: /* labelSmall, onGradientAlpha */),
      const SizedBox(height: AppSpacing.sp8),
      Text('₽ 12 450', style: /* amount, onGradient */),
      // progress bar, warnings live OUTSIDE this card, not inside
    ],
  ),
)
```

Must feel premium — this and the onboarding illustration/CTA are the only
two screens allowed a large green gradient element, one each.

### Transaction list tile

```dart
// Do NOT use ListTile. Build custom — see transaction_tile.dart:
// income  → icon accent on accentSoft circle, amount AppColors.positive
// expense → icon warning on warningSoft circle, amount AppColors.negative
// (symmetric treatment — expense is never just "neutral dark text")
```

### Segmented control / filter chip — selection state

```dart
// The OPTION the user taps, unselected:
color: AppColors.surface,               // NOT surfaceAlt
border: Border.all(color: AppColors.divider),
// selected:
color: AppColors.accent,  // or accentSubtle for a softer selected look
foregroundColor: AppColors.onAccent,
```

`surfaceAlt` is for passive grouping (an info card, an advice block) — not
for the fill of something the user presses.

### Primary button

```dart
FilledButton(...) // global FilledButtonTheme already does accent fill,
                   // onAccent text, radiusMd, elevation 0 — just use it.
```

> **Rule:** `elevation: 0` always. Only the onboarding CTA breaks the "flat
> accent" convention with a gradient fill (via `Material`+`InkWell` over a
> gradient `Container`, since `FilledButton` can't paint a gradient) — that
> is a deliberate, scoped exception, not a pattern to repeat elsewhere.

---

## Adaptivity (laptop/desktop browser windows)

`AppBreakpoints` (`app_theme.dart`): `desktop = 900`, `wideDesktop = 1180`.
Below `desktop` every screen keeps its mobile-first phone layout unchanged
(bottom tab bar, full-bleed content) — these breakpoints only affect
laptop/desktop windows, not phones.

- **`ResponsivePage`** (`lib/widgets/responsive_page.dart`) — wrap the body
  of any content screen (list/detail/settings-style screens) in it. It's a
  no-op below `desktop`; at/above it, centers content in a capped working
  width (`maxWidth`, default 640) instead of letting a mobile layout
  stretch edge-to-edge across a 1440px canvas. Don't hand-roll this with
  `ConstrainedBox`/`MediaQuery` checks.
- **Exception:** onboarding and login are the two screens *without*
  `ResponsivePage` — both have bespoke wide-viewport layouts (onboarding's
  `isWide` full-bleed split-screen; see `onboarding.dart`) that a generic
  width cap would break. Don't add `ResponsivePage` to either without
  redesigning the wide layout at the same time.
- **Hover cursor:** wrap non-button interactive elements (tappable cards,
  text links, settings rows — anything using `GestureDetector`/`InkWell`
  outside a Material button) in `HoverCursor` (`lib/core/widgets/
  hover_cursor.dart`) so desktop/web gets a hand cursor. Standard Material
  buttons (`FilledButton`, `OutlinedButton`, etc.) already get this from
  the theme — don't wrap those.

---

## Components

- `lib/core/widgets/floating_nav_bar.dart` — bottom tab bar (mobile) /
  sidebar (desktop), with built-in hover state on its tabs.
- `lib/core/widgets/empty_state.dart` — `EmptyState({icon, title,
  subtitle?, action?})`, the shared empty-list pattern (icon + title +
  optional subtitle + optional action). Use for any full-page "nothing
  here yet" state; don't hand-roll a private `_Empty` widget. Not a fit
  for compact inline empty rows (e.g. a single line inside a settings
  list) or empty states with a meaningfully different shape — those can
  stay bespoke rather than being forced through it.
- `lib/core/widgets/hover_cursor.dart` — see Adaptivity above.

---

## Screen-level notes

- **Statements** (`statements_screen.dart`) — list of uploaded bank
  statements with upload/delete; empty state via `EmptyState`.
- **Bank layer** (`bank_selection_screen.dart`, `bank_consent_screen.dart`,
  `bank_loading_screen.dart`, `connected_banks_screen.dart`) — connect flow
  (select bank → consent → loading) plus a settings-style management
  screen for already-connected banks.
- **Profile** (`profile_screen.dart`) — editable user profile (avatar,
  name, contact, business details); `settings.dart` shows a read-only
  mirror of the same `AppState` fields.
- **Period detail** (`period_detail_screen.dart`) — transactions for one
  tax period, with its own compact empty state (icon + single line, no
  title/action — deliberately not `EmptyState`).
- **Login** (`login_screen.dart`) — auth entry point (Google/phone/email);
  no `ResponsivePage` (see Adaptivity).

---

## What to avoid

| ❌ Avoid | ✅ Instead |
|----------|-----------|
| `Card` with default Material elevation/shadow | `Container` with `AppColors.surface` + `AppRadius.md` + border or `AppShadows.card` |
| `ListTile` for transactions | Custom Row layout (`TransactionTile`) |
| `DropdownButton` for category | Horizontal chip scroll |
| Raw `Color(0xFF...)` / `Colors.grey[200]` | `AppColors.*` token (bank brand hex is the one sanctioned exception) |
| A second green gradient anywhere | `AppGradients.primary` — the only one |
| `surfaceAlt` as a pressable chip/segment fill | `surface` + `divider` border |
| `elevation > 0` on cards or buttons | `elevation: 0`, shadow via `AppShadows.card`/`glow`/`glowSoft` only |
| Raw numeric `BorderRadius.circular(N)` | `AppRadius.sm/md/lg/xl/full` |
| Bare `fontSize:` literal | Named style in `app_text_styles.dart` |
| Inline `BoxShadow(...)` | `AppShadows.card`/`glow`/`glowSoft` |
| Hand-rolled width-cap / private `_Empty` widget | `ResponsivePage` / `EmptyState` |

---

## Naming conventions

```
lib/
  core/
    theme/
      app_colors.dart      — all colors here, nowhere else
      app_gradients.dart   — all named gradients
      app_shadows.dart     — card/glow/glowSoft, the only three BoxShadows
      app_theme.dart       — ThemeData, AppSpacing, AppRadius, AppBreakpoints
      app_text_styles.dart — named text style getters, the only fontSize literals
    widgets/                — floating_nav_bar, empty_state, hover_cursor
  features/
    dashboard/widgets/     — tax_summary_card.dart, metric_chip.dart, ...
    transactions/widgets/  — transaction_tile.dart, month_header.dart
```

> Every reusable piece of UI lives in a `widgets/` subfolder of its feature.
> No UI code in screen files beyond layout composition.

---

## Checklist before submitting any UI change

- [ ] No raw `Color(0xFF...)` / `Colors.*` outside `lib/core/theme/` (bank brand hex excepted)
- [ ] No `elevation` greater than 0 on cards or buttons
- [ ] White card: `AppShadows.card` **or** `divider` border, never both
- [ ] No `surfaceAlt` as the fill of a pressable chip/segment/button
- [ ] Radius only from `AppRadius` (`sm/md/lg/xl/full`)
- [ ] At most one large green gradient element per screen (`AppGradients.primary` only)
- [ ] Orange only on expense sums / warning badges / destructive-action outlines — never a button fill
- [ ] Every new widget has a `const` constructor where possible
- [ ] Empty state handled if the widget can receive an empty list (`EmptyState`, unless the shape genuinely doesn't fit)
- [ ] Amounts use the mono `amount`/`amountSmall`/`amountTiny` text styles (tabular figures)
- [ ] Spacing uses only `AppSpacing` values
- [ ] No bare `fontSize:` literal outside `app_text_styles.dart`
- [ ] No inline `BoxShadow` outside `app_shadows.dart`
- [ ] Content screen wrapped in `ResponsivePage` (unless it's onboarding/login)
- [ ] Non-button interactive elements wrapped in `HoverCursor`
