import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/tax_mode.dart';
import '../models/bank.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _apiCtrl;
  bool _apiVisible = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: context.read<AppState>().userName);
    _apiCtrl = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _apiCtrl.dispose();
    super.dispose();
  }

  void _saveName() {
    context.read<AppState>().setUserName(_nameCtrl.text.trim());
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Имя сохранено')));
  }

  void _saveApiKey() {
    context.read<AppState>().setApiKey(_apiCtrl.text.trim());
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('API ключ сохранён')));
  }

  void _clearData() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Сбросить данные?'),
        content: const Text(
            'Все операции, подключённые банки и настройки будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<AppState>().clearData();
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                  context, '/', (_) => false);
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          _Section(title: 'Оформление', children: [
            Row(
              children: [
                Icon(Icons.dark_mode_rounded,
                    size: 20, color: scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Тёмная тема',
                      style: TextStyle(
                          color: scheme.onSurface, fontWeight: FontWeight.w500)),
                ),
                Switch(
                  value: state.isDark,
                  onChanged: (_) => state.toggleTheme(),
                  activeColor: scheme.primary,
                  activeTrackColor: scheme.primaryContainer,
                ),
              ],
            ),
          ]),
          const SizedBox(height: 20),

          // ── Profile ─────────────────────────────────────────────────────
          _Section(title: 'Профиль', children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ваше имя',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: _saveName,
                  icon: const Icon(Icons.check_rounded),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 20),

          // ── Tax mode ────────────────────────────────────────────────────
          _Section(title: 'Налоговый режим', children: [
            _ModeSelector(
              selected: state.taxMode,
              onChanged: context.read<AppState>().setTaxMode,
            ),
          ]),
          const SizedBox(height: 20),

          // ── Banks ───────────────────────────────────────────────────────
          _Section(title: 'Подключённые банки', children: [
            if (state.connectedBanks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Нет подключённых банков',
                    style: TextStyle(color: scheme.onSurfaceVariant)),
              )
            else
              for (final bank in state.connectedBanks)
                _BankRow(
                  bank: bank,
                  onDisconnect: () =>
                      context.read<AppState>().disconnectBank(bank.bankId),
                ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/bank-select'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Добавить банк'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44)),
            ),
          ]),
          const SizedBox(height: 20),

          // ── AI ──────────────────────────────────────────────────────────
          _Section(title: 'AI классификация', children: [
            Text(
              'API ключ Anthropic (Claude) для умной классификации операций. '
              'Без ключа используется базовая классификация.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiCtrl,
              obscureText: !_apiVisible,
              decoration: InputDecoration(
                hintText: 'sk-ant-...',
                suffixIcon: IconButton(
                  icon: Icon(_apiVisible
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _apiVisible = !_apiVisible),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _saveApiKey,
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44)),
              child: const Text('Сохранить ключ'),
            ),
          ]),
          const SizedBox(height: 32),

          // ── Reset ───────────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: _clearData,
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.red, size: 20),
            label: const Text('Сбросить данные',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: Colors.red),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 1.2,
                color: scheme.onSurfaceVariant),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final TaxMode selected;
  final ValueChanged<TaxMode> onChanged;
  const _ModeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: TaxMode.values.map((mode) {
        final active = mode == selected;
        return GestureDetector(
          onTap: () => onChanged(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: active
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? scheme.primary : scheme.outline,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? scheme.primary : Colors.transparent,
                    border: Border.all(
                      color: active ? scheme.primary : scheme.onSurfaceVariant,
                      width: 2,
                    ),
                  ),
                  child: active
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mode.displayName,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: active
                                ? scheme.onPrimaryContainer
                                : scheme.onSurface)),
                    Text(mode.description,
                        style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BankRow extends StatelessWidget {
  final ConnectedBank bank;
  final VoidCallback onDisconnect;
  const _BankRow({required this.bank, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.account_balance_rounded,
                size: 18, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(bank.bankName,
                style: TextStyle(
                    fontWeight: FontWeight.w500, color: scheme.onSurface)),
          ),
          TextButton(
            onPressed: onDisconnect,
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            child: const Text('Отключить'),
          ),
        ],
      ),
    );
  }
}
