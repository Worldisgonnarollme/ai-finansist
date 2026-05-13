# AI Финансист

Мобильное и веб-приложение для автоматического учёта налогов самозанятых и ИП на УСН.

## Возможности

- **Автоматический расчёт налога** — НПД (4%/6%) и УСН 6% в реальном времени
- **Импорт банковских выписок** — PDF (Газпромбанк, Сбербанк) и CSV (Т-Банк и другие)
- **AI-классификация операций** — Anthropic Claude Haiku определяет тип дохода и назначение платежа
- **График доходов и расходов** — визуализация последних 6 месяцев
- **История по периодам** — детализация по каждому месяцу
- **Тёмная и светлая тема** — переключение в настройках

## Стек

| Категория | Инструменты |
|---|---|
| Framework | Flutter 3 (Web, iOS, Android) |
| State management | Provider (ChangeNotifier) |
| Хранение данных | SharedPreferences |
| AI | Anthropic Claude Haiku API |
| PDF парсинг | Syncfusion Flutter PDF |
| Графики | fl_chart |
| Localisation | intl (ru_RU) |

## Запуск

```bash
flutter pub get
flutter run -d chrome      # веб
flutter run -d ios         # iOS симулятор
flutter run -d android     # Android эмулятор
```

Для AI-классификации добавьте API ключ Anthropic в **Настройки → AI классификация**.  
Без ключа работает базовая классификация по ключевым словам.

## Структура

```
lib/
├── models/          # Transaction, TaxPeriod, TaxMode, Bank, MonthStat
├── services/        # TaxCalculator, AiService, PdfService, CsvService, BankService
├── screens/         # Dashboard, History, Settings, Onboarding, PeriodDetail
└── widgets/         # TaxSummaryCard, MonthlyChart, TransactionCard, AdviceCard
```
