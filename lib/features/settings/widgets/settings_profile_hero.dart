import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../onboarding/widgets/grain_overlay.dart';

/// Hero-карточка профиля — орб+зерно на фоне сцены, аватар, имя/e-mail,
/// чипы режима и статуса банков. Desktop: кнопка «Изменить профиль»
/// справа. Mobile (compact): кнопки нет — вся карта тап-зона, шеврон
/// справа (см. §4/§10 промпта).
class SettingsProfileHero extends StatefulWidget {
  final String avatarBase64;
  final String name;
  final String email;
  final String taxModeLabel;
  final bool banksConnected;
  final VoidCallback onTap;
  final bool compact;

  const SettingsProfileHero({
    super.key,
    required this.avatarBase64,
    required this.name,
    required this.email,
    required this.taxModeLabel,
    required this.banksConnected,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<SettingsProfileHero> createState() => _SettingsProfileHeroState();
}

class _SettingsProfileHeroState extends State<SettingsProfileHero> {
  bool _hovered = false;

  String get _initials {
    final parts = widget.name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatarSize = widget.compact ? 56.0 : 72.0;
    final orbSize = widget.compact ? 240.0 : 340.0;

    final avatar = Container(
      width: avatarSize,
      height: avatarSize,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.onbGreenDeep.withValues(alpha: 0.45),
            blurRadius: 24,
            spreadRadius: -10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: widget.avatarBase64.isNotEmpty
          ? Image.memory(base64Decode(widget.avatarBase64), fit: BoxFit.cover, width: avatarSize, height: avatarSize)
          : Text(
              _initials,
              style: AppTextStyles.onbAmount.copyWith(
                fontSize: widget.compact ? 19 : 24,
                color: AppColors.onbCard,
              ),
            ),
    );

    final info = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.name.isNotEmpty ? widget.name : 'Пользователь',
            style: widget.compact ? AppTextStyles.settingsHeroName.copyWith(fontSize: 17) : AppTextStyles.settingsHeroName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: widget.compact ? 1 : 2),
          Padding(
            padding: EdgeInsets.only(bottom: widget.compact ? 8 : 12),
            child: Text(
              widget.email.isNotEmpty ? widget.email : 'E-mail не указан',
              style: widget.compact ? AppTextStyles.settingsHeroMail.copyWith(fontSize: 12.5) : AppTextStyles.settingsHeroMail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Wrap(
            spacing: widget.compact ? 6 : 8,
            runSpacing: 6,
            children: [
              _Chip(label: widget.taxModeLabel, orange: false, compact: widget.compact),
              if (!widget.banksConnected)
                _Chip(label: 'Банки не подключены', orange: true, compact: widget.compact),
            ],
          ),
        ],
      ),
    );

    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppGradients.onbSceneBg,
        border: Border.all(color: AppColors.onbCard.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(widget.compact ? AppRadius.lg - 2 : AppRadius.xl - 4),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: widget.compact ? -110 : -130,
            child: Opacity(
              opacity: 0.55,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: orbSize,
                  height: orbSize,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.onbOrb),
                ),
              ),
            ),
          ),
          const GrainOverlay(opacity: 0.1),
          Padding(
            padding: widget.compact
                ? const EdgeInsets.all(AppSpacing.sp20)
                : const EdgeInsets.symmetric(horizontal: AppSpacing.sp32, vertical: AppSpacing.sp24 + 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatar,
                SizedBox(width: widget.compact ? AppSpacing.sp16 - 2 : AppSpacing.sp24 - 2),
                info,
                if (widget.compact)
                  const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.onbInkSoft)
                else
                  _EditProfileButton(hovered: _hovered),
              ],
            ),
          ),
        ],
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.onTap, child: card),
    );
  }
}

class _EditProfileButton extends StatelessWidget {
  final bool hovered;
  const _EditProfileButton({required this.hovered});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp20, vertical: AppSpacing.sp12),
          decoration: BoxDecoration(
            color: AppColors.onbCard.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: hovered ? AppColors.onbGreen : AppColors.onbLine),
          ),
          child: Text(
            'Изменить профиль',
            style: AppTextStyles.onbCta.copyWith(
              fontSize: 14,
              color: hovered ? AppColors.onbGreen : AppColors.onbInk,
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool orange;
  final bool compact;
  const _Chip({required this.label, required this.orange, required this.compact});

  @override
  Widget build(BuildContext context) {
    final fg = orange ? AppColors.onbOrangeText : AppColors.onbGreen;
    final bg = orange ? AppColors.onbOrangeSoft : AppColors.onbGreenSoft;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 5 : 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 4 : 5,
            height: compact ? 4 : 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: fg),
          ),
          SizedBox(width: compact ? 5 : 6),
          Text(label, style: AppTextStyles.onbChip.copyWith(fontSize: compact ? 11 : 12, color: fg)),
        ],
      ),
    );
  }
}
