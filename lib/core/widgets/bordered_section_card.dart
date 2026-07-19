import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Белая карточка со списком строк под uppercase-заголовком секции —
/// экраны "История"/"Выписки" (см. history_statements_prompt). Строки
/// разделены тонкой линией, кроме первой.
class BorderedSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const BorderedSectionCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.onbCard,
        border: Border.all(color: AppColors.onbLine),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sp16 + 2,
              AppSpacing.sp12 + 2,
              AppSpacing.sp16 + 2,
              AppSpacing.sp8 + 2,
            ),
            child: Text(title.toUpperCase(), style: AppTextStyles.settingsGroupTitle),
          ),
          for (int i = 0; i < children.length; i++) ...[
            if (i != 0) const Divider(height: 1, color: AppColors.onbLine),
            children[i],
          ],
        ],
      ),
    );
  }
}
