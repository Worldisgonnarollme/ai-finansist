import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../app_state.dart';
import '../models/tax_mode.dart';
import '../main.dart';
import '../widgets/tax_summary_card.dart';
import '../widgets/advice_card.dart';
import '../widgets/monthly_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: scheme.error,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: state.clearError,
            ),
          ),
        );
        state.clearError();
      }
    });

    return Scaffold(
      body: RefreshIndicator(
        color: scheme.primary,
        onRefresh: state.hasBanks ? state.refreshData : () async {},
        child: CustomScrollView(
          slivers: [
            _buildHeader(context, state, scheme, isDark),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeSlideItem(index: 0, child: TaxSummaryCard(state: state)),
                  const SizedBox(height: 16),
                  FadeSlideItem(
                      index: 1, child: _IncomeExpenseRow(state: state)),
                  const SizedBox(height: 24),
                  FadeSlideItem(
                      index: 2, child: _ActionButtons(state: state)),
                  const SizedBox(height: 24),
                  FadeSlideItem(
                    index: 3,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: MonthlyChart(data: state.last6MonthsData),
                      ),
                    ),
                  ),
                  if (state.advice.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    FadeSlideItem(
                        index: 4, child: AdviceCard(text: state.advice)),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildHeader(
      BuildContext ctx, AppState state, ColorScheme scheme, bool isDark) {
    final greeting = _greeting();
    final name = state.userName.isNotEmpty ? state.userName : 'Привет';
    final gradStart =
        isDark ? const Color(0xFF0D1829) : const Color(0xFFBF6200);
    final gradEnd =
        isDark ? const Color(0xFF162236) : const Color(0xFFE8820C);

    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF0D1829) : const Color(0xFFBF6200),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, $name',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            Text(
              '${state.taxMode.shortName} · ${state.taxMode.description}',
              style:
                  TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradStart, gradEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Доброе утро';
    if (h < 18) return 'Добрый день';
    return 'Добрый вечер';
  }
}

class _IncomeExpenseRow extends StatelessWidget {
  final AppState state;
  const _IncomeExpenseRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Доходы',
            value: state.currentIncome.rub,
            color: scheme.secondary,
            icon: Icons.trending_up_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Расходы',
            value: state.currentExpenses.rub,
            color: scheme.error,
            icon: Icons.trending_down_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        color: scheme.onSurfaceVariant, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              key: ValueKey(value),
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (_, v, child) =>
                  Transform.scale(scale: v, alignment: Alignment.centerLeft, child: child),
              child: Text(
                value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final AppState state;
  const _ActionButtons({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (state.loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: CircularProgressIndicator(color: scheme.primary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!state.hasBanks)
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/bank-select'),
            icon: const Icon(Icons.account_balance_rounded),
            label: const Text('Подключить банк'),
          )
        else
          FilledButton.icon(
            onPressed: state.refreshData,
            icon: const Icon(Icons.sync_rounded),
            label: const Text('Обновить данные'),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickFile(context),
                icon: const Icon(Icons.upload_file_rounded, size: 20),
                label: const Text('Выписка'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/add-tx'),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Вручную'),
              ),
            ),
          ],
        ),
        if (state.hasBanks) ...[
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/bank-select'),
            icon: Icon(Icons.add_rounded, size: 16, color: scheme.primary),
            label: Text('Добавить банк',
                style: TextStyle(color: scheme.primary)),
          ),
        ],
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
      ctx.read<AppState>().importFile(file.bytes!.toList(), ext);
    }
  }
}
