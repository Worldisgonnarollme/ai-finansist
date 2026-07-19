import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

/// Строка настройки: иконка + текст + значение/чип/тумблер справа.
/// Клик по всей строке; hover — на desktop (compact:false), pressed-фон —
/// на mobile (compact:true), см. settings_page_prompt §6/§10.
class SettingsRow extends StatefulWidget {
  final IconData icon;
  final bool iconOrange;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;
  final bool compact;

  const SettingsRow({
    super.key,
    required this.icon,
    this.iconOrange = false,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<SettingsRow> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final iconBg = widget.iconOrange ? AppColors.onbOrangeSoft : AppColors.onbGreenSoft;
    final iconFg = widget.iconOrange ? AppColors.onbOrangeText : AppColors.onbGreen;
    final iconSize = widget.compact ? 36.0 : 38.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: (_hovered && !widget.compact)
              ? AppColors.onbGreen.withValues(alpha: 0.045)
              : (_pressed && widget.compact)
                  ? AppColors.onbGreen.withValues(alpha: 0.05)
                  : Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? AppSpacing.sp16 : AppSpacing.sp24,
            vertical: AppSpacing.sp12 + 2,
          ),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(widget.compact ? AppRadius.sm - 1 : AppRadius.sm),
                ),
                child: Icon(widget.icon, size: 17, color: iconFg),
              ),
              SizedBox(width: widget.compact ? AppSpacing.sp12 : AppSpacing.sp12 + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: widget.compact
                          ? AppTextStyles.settingsRowTitle.copyWith(fontSize: 14.5)
                          : AppTextStyles.settingsRowTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.subtitle,
                      style: widget.compact
                          ? AppTextStyles.settingsRowSubtitle.copyWith(fontSize: 12)
                          : AppTextStyles.settingsRowSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sp12),
              widget.trailing,
            ],
          ),
        ),
      ),
    );
  }
}

const _chevron = Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.onbInkSoft);

/// Просто шеврон (для строк без явного значения — hero-подобные переходы).
class SettingsChevron extends StatelessWidget {
  const SettingsChevron({super.key});

  @override
  Widget build(BuildContext context) => _chevron;
}

/// Значение + шеврон (обычный `val` в HTML-эталоне).
class SettingsValueTrailing extends StatelessWidget {
  final String value;
  const SettingsValueTrailing({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Text(
            value,
            style: AppTextStyles.settingsRowValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 6),
        _chevron,
      ],
    );
  }
}

/// Чип-статус + шеврон (например «УСН» или «Не подключены»).
class SettingsChipTrailing extends StatelessWidget {
  final String label;
  final bool orange;
  const SettingsChipTrailing({super.key, required this.label, this.orange = false});

  @override
  Widget build(BuildContext context) {
    final fg = orange ? AppColors.onbOrangeText : AppColors.onbGreen;
    final bg = orange ? AppColors.onbOrangeSoft : AppColors.onbGreenSoft;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp8 + 2, vertical: 4),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
          child: Text(label, style: AppTextStyles.onbChip.copyWith(color: fg)),
        ),
        const SizedBox(width: 6),
        _chevron,
      ],
    );
  }
}
