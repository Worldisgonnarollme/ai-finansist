import 'package:flutter/material.dart';
import '../data/russian_regions.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Модальный поиск по списку регионов РФ (89 субъектов — без поиска
/// пришлось бы листать весь список). Возвращает выбранный регион или
/// null, если закрыли без выбора.
Future<String?> showRegionPicker(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.onbCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => _RegionPickerSheet(current: current),
  );
}

class _RegionPickerSheet extends StatefulWidget {
  final String? current;
  const _RegionPickerSheet({this.current});

  @override
  State<_RegionPickerSheet> createState() => _RegionPickerSheetState();
}

class _RegionPickerSheetState extends State<_RegionPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    if (_query.isEmpty) return russianRegions;
    final q = _query.toLowerCase();
    return russianRegions.where((r) => r.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.sp12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onbLine,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sp20,
                AppSpacing.sp16,
                AppSpacing.sp20,
                AppSpacing.sp8,
              ),
              child: Text('Регион', style: AppTextStyles.taxRegimeCardName),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp20),
              child: TextField(
                controller: _searchCtrl,
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                style: AppTextStyles.taxRegimeDesc.copyWith(color: AppColors.onbInk),
                decoration: InputDecoration(
                  hintText: 'Поиск региона',
                  hintStyle: AppTextStyles.taxRegimeDesc,
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.onbInkSoft),
                  filled: true,
                  fillColor: AppColors.onbBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sp12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.onbLine),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.onbLine),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.onbGreen),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sp8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text('Ничего не найдено', style: AppTextStyles.taxRegimeDesc),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sp20,
                        vertical: AppSpacing.sp8,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.onbLine),
                      itemBuilder: (_, i) {
                        final region = filtered[i];
                        final selected = region == widget.current;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            region,
                            style: AppTextStyles.taxRegimeDesc.copyWith(
                              color: selected ? AppColors.onbGreen : AppColors.onbInk,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(Icons.check_rounded, color: AppColors.onbGreen)
                              : null,
                          onTap: () => Navigator.pop(context, region),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
