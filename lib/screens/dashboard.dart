import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../app_state.dart';
import '../models/tax_mode.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../main.dart';
import '../services/tax_calculator.dart';
import '../features/dashboard/widgets/tax_summary_card.dart';
import '../features/dashboard/widgets/metric_chip.dart';
import '../features/dashboard/widgets/recent_transactions_list.dart';
import '../widgets/advice_card.dart';
import '../widgets/monthly_chart.dart';
import '../widgets/warning_banner.dart';
import '../widgets/responsive_page.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.error!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            backgroundColor: AppColors.surfaceAlt,
            action: SnackBarAction(
              label: 'OK',
              textColor: AppColors.accent,
              onPressed: state.clearError,
            ),
          ),
        );
        state.clearError();
      }
    });

    // На широком ноутбучном/десктопном окне однoколоночная лента с
    // hero-карточкой шириной во весь экран смотрится как растянутая
    // мобильная страница. С AppBreakpoints.wideDesktop используем реальную
    // 2-колоночную раскладку (числа+действия слева, активность+советы
    // справа), а не просто добавляем поля по краям.
    final isWide =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.wideDesktop;
    // Отдельная (более низкая) отметка — есть ли внизу плавающая пилюля
    // навигации (MainScreen переключается на боковую панель уже с 900px,
    // раньше, чем эта самая _NarrowBody перестаёт рендериться на 1180px)
    // или сама навигация вообще не занимает низ экрана. От неё зависит,
    // нужен ли динамический нижний паддинг под пилюлю, а не статичный.
    final hasFloatingNav =
        MediaQuery.sizeOf(context).width < AppBreakpoints.desktop;
    final narrowBottomPadding = hasFloatingNav
        ? MediaQuery.paddingOf(context).bottom + AppSpacing.sp16
        : AppSpacing.sp32 + AppSpacing.sp24;

    return Scaffold(
      body: SafeArea(
        // bottom: false — нижний safe-area/отступ под пилюлю считает сама
        // _NarrowBody (narrowBottomPadding), через MediaQuery.paddingOf,
        // а не эта SafeArea — иначе оба отступа сложатся и внизу появится
        // лишний пустой промежуток.
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surfaceAlt,
          onRefresh: state.hasBanks ? state.refreshData : () async {},
          child: isWide
              ? _WideBody(state: state)
              : ResponsivePage(
                  maxWidth: 640,
                  child: _NarrowBody(
                    state: state,
                    bottomPadding: narrowBottomPadding,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Раскладка для телефона и обычного desktop-окна (< wideDesktop) ────────

class _NarrowBody extends StatelessWidget {
  final AppState state;
  final double bottomPadding;
  const _NarrowBody({required this.state, required this.bottomPadding});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.sp18,
            AppSpacing.sp8,
            AppSpacing.sp18,
            bottomPadding,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              FadeSlideItem(index: 0, child: _Header(state: state)),
              const SizedBox(height: AppSpacing.sp16),
              FadeSlideItem(index: 1, child: TaxSummaryCard(state: state)),
              FadeSlideItem(index: 2, child: _Warnings(state: state)),
              const SizedBox(height: AppSpacing.sp16),
              FadeSlideItem(index: 3, child: _IncomeExpenseRow(state: state)),
              const SizedBox(height: AppSpacing.sp16 - 2),
              FadeSlideItem(index: 4, child: _ActionButtons(state: state)),
              const SizedBox(height: AppSpacing.sp20),
              FadeSlideItem(index: 5, child: _ChartCard(state: state)),
              if (state.advice.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sp16 - 2),
                FadeSlideItem(index: 6, child: AdviceCard(text: state.advice)),
              ],
              const SizedBox(height: AppSpacing.sp20),
              FadeSlideItem(index: 7, child: _RecentList(state: state)),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Раскладка для широкого desktop-окна (≥ wideDesktop) ────────────────────

class _WideBody extends StatelessWidget {
  final AppState state;
  const _WideBody({required this.state});

  static const _leftWidth = 620.0;
  static const _rightWidth = 360.0;
  static const _gap = AppSpacing.sp32;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sp24,
            AppSpacing.sp16,
            AppSpacing.sp24,
            AppSpacing.sp48,
          ),
          sliver: SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: _leftWidth + _gap + _rightWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideItem(index: 0, child: _Header(state: state)),
                    const SizedBox(height: AppSpacing.sp20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: _leftWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FadeSlideItem(
                                index: 1,
                                child: TaxSummaryCard(state: state),
                              ),
                              FadeSlideItem(
                                index: 2,
                                child: _Warnings(state: state),
                              ),
                              const SizedBox(height: AppSpacing.sp16),
                              FadeSlideItem(
                                index: 3,
                                child: _IncomeExpenseRow(state: state),
                              ),
                              const SizedBox(height: AppSpacing.sp16 - 2),
                              FadeSlideItem(
                                index: 4,
                                child: _ActionButtons(state: state),
                              ),
                              const SizedBox(height: AppSpacing.sp20),
                              FadeSlideItem(
                                index: 5,
                                child: _ChartCard(state: state),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: _gap),
                        SizedBox(
                          width: _rightWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (state.advice.isNotEmpty) ...[
                                FadeSlideItem(
                                  index: 6,
                                  child: AdviceCard(text: state.advice),
                                ),
                                const SizedBox(height: AppSpacing.sp20),
                              ],
                              FadeSlideItem(
                                index: 7,
                                child: _RecentList(state: state),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final AppState state;
  const _ChartCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sp16 - 2,
        AppSpacing.sp16,
        AppSpacing.sp16 - 2,
        AppSpacing.sp8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
      ),
      child: MonthlyChart(data: state.last6MonthsData),
    );
  }
}

class _RecentList extends StatelessWidget {
  final AppState state;
  const _RecentList({required this.state});

  @override
  Widget build(BuildContext context) {
    return RecentTransactionsList(
      transactions: state.recentTransactions,
      onSeeAll: () => Navigator.pushNamed(
        context,
        '/period',
        arguments: {
          'year': state.displayMonth.year,
          'month': state.displayMonth.month,
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AppState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    final name = state.userName.isNotEmpty ? state.userName : 'пользователь';
    final status = state.taxMode == TaxMode.npd ? 'Самозанятый' : 'ИП';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()}, $name',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sp8 - 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp8 + 2,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$status · ${state.taxMode.shortName}',
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sp12),
        _NotificationButton(),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Доброе утро';
    if (h < 18) return 'Добрый день';
    return 'Добрый вечер';
  }
}

// Декоративная кнопка-колокольчик в шапке дашборда (по референсу дизайна).
// Уведомлений как отдельной фичи в приложении нет — тап просто закрывает
// подсказку, ничего не ломает и не подменяет существующую логику.
class _NotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Новых уведомлений нет'),
          backgroundColor: AppColors.surfaceAlt,
        ),
      ),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider),
        ),
        child: const Icon(
          Icons.notifications_none_rounded,
          size: 18,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// Риск-баннеры (лимит дохода/НДС, лимит сотрудников, неразмеченные
// операции) + нейтральная заметка о текущей ступени шкалы НДФЛ (только
// ОСНО) — та же бизнес-логика и те же условия, что и раньше, просто
// вынесены из-под градиентной карточки в собственные светлые баннеры.
class _Warnings extends StatelessWidget {
  final AppState state;
  const _Warnings({required this.state});

  @override
  Widget build(BuildContext context) {
    final result = state.currentTaxResult;
    final children = <Widget>[];

    if (result.incomeLimitWarning || result.vatApplicable) {
      children.add(
        WarningBanner(
          icon: Icons.warning_amber_rounded,
          text:
              result.incomeLimitMessage ??
              (result.vatApplicable
                  ? 'Доход > 20 млн ₽ — возникает обязанность по НДС'
                  : ''),
        ),
      );
    }
    if (result.employeeLimitWarning) {
      children.add(
        WarningBanner(
          icon: Icons.warning_amber_rounded,
          text: result.employeeLimitMessage ?? '',
        ),
      );
    }
    if (result.hasUndefinedTransactions) {
      children.add(
        WarningBanner(
          icon: Icons.error_outline_rounded,
          text: result.undefinedMessage,
          showChevron: true,
          onTap: () => Navigator.pushNamed(
            context,
            '/period',
            arguments: {
              'year': state.displayMonth.year,
              'month': state.displayMonth.month,
            },
          ),
        ),
      );
    }
    if (state.taxMode == TaxMode.osno) {
      children.add(_NdflScaleNote(annualIncome: state.currentYearIncome));
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sp16 - 2),
      child: Column(
        children: [
          for (final w in children) ...[
            w,
            if (w != children.last) const SizedBox(height: AppSpacing.sp12),
          ],
        ],
      ),
    );
  }
}

// Прогрессивная шкала НДФЛ (ст. 224 НК РФ, действует с 2025 года) —
// (ставка, описание диапазона дохода, значение ставки для сравнения
// с TaxCalculator.ndflBracket, чтобы подсветить актуальную строку).
const List<(String, String, double)> _ndflScale = [
  ('13%', 'доход до 2,4 млн рублей', 0.13),
  ('15%', 'доход от 2,4 до 5 млн рублей', 0.15),
  ('18%', 'доход от 5 до 20 млн рублей', 0.18),
  ('20%', 'доход от 20 до 50 млн рублей', 0.20),
  ('22%', 'доход более 50 млн рублей', 0.22),
];

class _NdflScaleNote extends StatelessWidget {
  final double annualIncome;
  const _NdflScaleNote({required this.annualIncome});

  @override
  Widget build(BuildContext context) {
    final currentRate = TaxCalculator.ndflBracket(annualIncome).rate;
    final current = _ndflScale.firstWhere((b) => b.$3 == currentRate);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp16 - 2,
        vertical: AppSpacing.sp12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sp8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'НДФЛ ${current.$1} — ${current.$2}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'НДС 22% с дохода за период (ст. 164 НК РФ)',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                    height: 1.4,
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

class _IncomeExpenseRow extends StatelessWidget {
  final AppState state;
  const _IncomeExpenseRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MetricChip(
            label: 'Доходы',
            value: state.currentIncome.rub,
            icon: Icons.arrow_upward_rounded,
            isPositive: true,
          ),
        ),
        const SizedBox(width: AppSpacing.sp12 - 2),
        Expanded(
          child: MetricChip(
            label: 'Расходы',
            value: state.currentExpenses.rub,
            icon: Icons.arrow_downward_rounded,
            isPositive: false,
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final AppState state;
  const _ActionButtons({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.sp24 + AppSpacing.sp4,
          ),
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: state.hasBanks
                  ? OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/bank-select'),
                      icon: const Icon(Icons.account_balance_rounded, size: 18),
                      label: const Text('Добавить банк'),
                    )
                  : OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/bank-select'),
                      icon: const Icon(Icons.account_balance_rounded, size: 18),
                      label: const Text('Подключить банк'),
                    ),
            ),
            const SizedBox(width: AppSpacing.sp8 + 2),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/add-tx'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Операция'),
              ),
            ),
          ],
        ),
        if (state.hasBanks) ...[
          const SizedBox(height: AppSpacing.sp8),
          FilledButton.icon(
            onPressed: state.refreshData,
            icon: const Icon(Icons.sync_rounded, size: 18),
            label: const Text('Обновить данные'),
          ),
        ],
        const SizedBox(height: AppSpacing.sp8),
        OutlinedButton.icon(
          onPressed: () => _pickFile(context),
          icon: const Icon(Icons.upload_file_rounded, size: 18),
          label: const Text('Загрузить выписку'),
        ),
      ],
    );
  }

  Future<void> _pickFile(BuildContext ctx) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.first.bytes == null) return;
    final file = result.files.first;
    final ext = (file.extension ?? '').toLowerCase();
    if (ctx.mounted) {
      ctx.read<AppState>().importFile(
        file.bytes!.toList(),
        ext,
        fileName: file.name,
      );
    }
  }
}
