import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../widgets/screen_header.dart';

/// Simple profile form — name/phone/ИНН/ОГРНИП, read-only display style
/// matching the mock (swap the plain Containers for TextFields when wiring
/// real editing).
class ProfileScreen extends StatefulWidget {
  final VoidCallback onBack;
  const ProfileScreen({super.key, required this.onBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _saved = false;

  void _save() {
    setState(() => _saved = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: 'Профиль', onBack: widget.onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: const [
                  _Field(label: 'Имя', value: 'Алексей Воронцов'),
                  SizedBox(height: 14),
                  _Field(label: 'Телефон', value: '+7 903 123-45-67'),
                  SizedBox(height: 14),
                  _Field(label: 'ИНН', value: '770812345678', mono: true),
                  SizedBox(height: 14),
                  _Field(label: 'ОГРНИП', value: '321774600098765', mono: true),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_saved ? 'Сохранено ✓' : 'Сохранить', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  const _Field({required this.label, required this.value, this.mono = false});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.textTertiary)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(color: AppColors.surfaceAlt.withOpacity(0.5), border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(11)),
            child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: mono ? 'JetBrainsMono' : null)),
          ),
        ],
      );
}
