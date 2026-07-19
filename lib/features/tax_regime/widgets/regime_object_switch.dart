import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../data/tax_regimes_meta.dart';

/// Переключатель объекта налогообложения (Доходы / Доходы − расходы)
/// внутри раскрытой карточки УСН/АУСН. Тап не должен всплывать до
/// карточки-аккордеона — вызывающая сторона оборачивает это в свой
/// GestureDetector с [Listener]/`onTapDown` стопом, см. RegimeAccordionCard.
class RegimeObjectSwitch extends StatelessWidget {
  final List<TaxRegimeObject> objects;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool compact;

  const RegimeObjectSwitch({
    super.key,
    required this.objects,
    required this.selectedIndex,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < objects.length; i++) ...[
          if (i != 0) const SizedBox(width: AppSpacing.sp8),
          Expanded(
            child: _ObjectButton(
              label: compact ? objects[i].labelCompact : objects[i].label,
              active: i == selectedIndex,
              compact: compact,
              onTap: () => onChanged(i),
            ),
          ),
        ],
      ],
    );
  }
}

class _ObjectButton extends StatelessWidget {
  final String label;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  const _ObjectButton({
    required this.label,
    required this.active,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sp4 + 2 : AppSpacing.sp12,
          vertical: compact ? AppSpacing.sp12 - 1 : AppSpacing.sp12,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.onbGreenSoft : AppColors.onbCard,
          borderRadius: BorderRadius.circular(compact ? 11 : AppRadius.sm),
          border: Border.all(
            color: active ? AppColors.onbGreen : AppColors.onbLine,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              (compact
                      ? AppTextStyles.taxRegimeObjectLabel.copyWith(
                          fontSize: 12,
                        )
                      : AppTextStyles.taxRegimeObjectLabel)
                  .copyWith(color: active ? AppColors.onbGreen : AppColors.onbInkSoft),
        ),
      ),
    );
  }
}
