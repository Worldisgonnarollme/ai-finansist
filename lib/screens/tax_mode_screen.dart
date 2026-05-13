import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/tax_mode.dart';

class TaxModeScreen extends StatefulWidget {
  const TaxModeScreen({super.key});

  @override
  State<TaxModeScreen> createState() => _TaxModeScreenState();
}

class _TaxModeScreenState extends State<TaxModeScreen> {
  TaxMode _selected = TaxMode.npd;

  void _continue() {
    context.read<AppState>().setTaxMode(_selected);
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              const Text(
                'Выберите\nналоговый режим',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Это можно изменить в настройках',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
              const SizedBox(height: 40),
              _ModeCard(
                mode: TaxMode.npd,
                selected: _selected == TaxMode.npd,
                onTap: () => setState(() => _selected = TaxMode.npd),
              ),
              const SizedBox(height: 16),
              _ModeCard(
                mode: TaxMode.usn6,
                selected: _selected == TaxMode.usn6,
                onTap: () => setState(() => _selected = TaxMode.usn6),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _continue,
                style: FilledButton.styleFrom(backgroundColor: scheme.primary),
                child: const Text('Продолжить'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final TaxMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard(
      {required this.mode, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? scheme.primary : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.primary : Colors.grey.shade400,
                  width: 2,
                ),
                color: selected ? scheme.primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: selected
                          ? scheme.onPrimaryContainer
                          : const Color(0xFF1A1C2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mode.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: selected
                          ? scheme.onPrimaryContainer.withOpacity(0.7)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
