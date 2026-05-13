import 'package:flutter/material.dart';
import '../models/bank.dart';

class BankConsentScreen extends StatelessWidget {
  final Bank bank;
  const BankConsentScreen({super.key, required this.bank});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(bank.name),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: bank.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    bank.name[0],
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Доступ к данным',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            _SectionLabel(label: 'Мы получим:', icon: Icons.check_circle_rounded,
                color: const Color(0xFF2E7D32)),
            const SizedBox(height: 12),
            _PermItem(text: 'Список операций по счёту'),
            _PermItem(text: 'Суммы и даты платежей'),
            _PermItem(text: 'Назначение платежей'),
            const SizedBox(height: 24),
            _SectionLabel(label: 'Мы НЕ будем:', icon: Icons.cancel_rounded,
                color: const Color(0xFFC62828)),
            const SizedBox(height: 12),
            _PermItem(text: 'Совершать платежи', negative: true),
            _PermItem(text: 'Видеть остаток на счёте', negative: true),
            _PermItem(text: 'Хранить пароль от банка', negative: true),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: scheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Вы можете отозвать доступ в любой момент в настройках.',
                      style: TextStyle(
                          color: scheme.onPrimaryContainer, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pushReplacementNamed(
                  context, '/bank-loading',
                  arguments: bank),
              child: const Text('Даю согласие'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionLabel(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: color)),
      ],
    );
  }
}

class _PermItem extends StatelessWidget {
  final String text;
  final bool negative;
  const _PermItem({required this.text, this.negative = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Row(
        children: [
          Icon(
            negative ? Icons.remove_circle_outline : Icons.check_rounded,
            size: 18,
            color: negative
                ? const Color(0xFFC62828)
                : const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
