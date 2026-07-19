import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../main.dart';
import '../data/tax_regimes_meta.dart';
import 'regime_object_switch.dart';

/// Карточка-аккордеон одного налогового режима (§5 tax_regime_prompt.md,
/// эталоны docs/design/tax_regime_{desktop,mobile}_v3.html). Тап по
/// карточке = выбор + раскрытие одним действием; раскрыта всегда ровно
/// одна — выбранная. Повторный тап по уже выбранной карточке — no-op,
/// как в эталонном HTML (клик там не снимает выбор и не сворачивает).
class RegimeAccordionCard extends StatelessWidget {
  final TaxRegimeItem item;
  final bool selected;
  final int objIndex;
  final ValueChanged<int> onObjectChanged;
  final VoidCallback onSelect;
  final bool compact;
  // Причина недоступности режима в выбранном регионе (например, "АУСН не
  // введена в Нижегородской области") — если задана И режим ещё не выбран
  // (не selected), карточка блокирует выбор и подсвечивает причину вместо
  // метки "для кого". Уже сохранённый ранее выбор не отбирается — если
  // регион сменили задним числом, карточка остаётся как есть.
  final String? unavailableNote;

  const RegimeAccordionCard({
    super.key,
    required this.item,
    required this.selected,
    required this.objIndex,
    required this.onObjectChanged,
    required this.onSelect,
    this.compact = false,
    this.unavailableNote,
  });

  @override
  Widget build(BuildContext context) {
    final rateOrange = item.rateTone == TaxRegimeRateTone.orange;
    final hPad = compact ? AppSpacing.sp16 : AppSpacing.sp20 + 2;
    final blocked = unavailableNote != null && !selected;

    return GestureDetector(
      onTap: blocked
          ? () => rootMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text(unavailableNote!),
                backgroundColor: AppColors.onbDanger,
              ),
            )
          : onSelect,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: selected ? AppColors.onbSelectedTint : AppColors.onbCard,
          borderRadius: BorderRadius.circular(compact ? 16 : 18),
          border: Border.all(
            color: selected ? AppColors.onbGreen : AppColors.onbLine,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: hPad,
                vertical: compact ? AppSpacing.sp16 - 1 : AppSpacing.sp18,
              ),
              child: Row(
                children: [
                  Opacity(
                    opacity: blocked ? 0.45 : 1,
                    child: Text(
                      item.name,
                      style: compact
                          ? AppTextStyles.taxRegimeCardName.copyWith(
                              fontSize: 15.5,
                            )
                          : AppTextStyles.taxRegimeCardName,
                    ),
                  ),
                  SizedBox(
                    width: compact ? AppSpacing.sp8 + 1 : AppSpacing.sp12,
                  ),
                  Opacity(
                    opacity: blocked ? 0.45 : 1,
                    child: _RateChip(
                      label: compact ? item.rateCompact : item.rate,
                      orange: rateOrange,
                      compact: compact,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      blocked ? unavailableNote! : item.who,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style:
                          (compact
                                  ? AppTextStyles.taxRegimeWho.copyWith(fontSize: 10.5)
                                  : AppTextStyles.taxRegimeWho)
                              .copyWith(color: blocked ? AppColors.onbDanger : null),
                    ),
                  ),
                  SizedBox(width: compact ? AppSpacing.sp8 : AppSpacing.sp12),
                  Opacity(
                    opacity: blocked ? 0.45 : 1,
                    child: _CheckCircle(active: selected, compact: compact),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: selected
                  ? _CardBody(
                      item: item,
                      objIndex: objIndex,
                      onObjectChanged: onObjectChanged,
                      hPad: hPad,
                      compact: compact,
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  final TaxRegimeItem item;
  final int objIndex;
  final ValueChanged<int> onObjectChanged;
  final double hPad;
  final bool compact;

  const _CardBody({
    required this.item,
    required this.objIndex,
    required this.onObjectChanged,
    required this.hPad,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final objects = item.objects;
    final facts = compact ? item.factsCompact : item.facts;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        hPad,
        0,
        hPad,
        compact ? AppSpacing.sp16 : AppSpacing.sp20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.description,
            style: compact
                ? AppTextStyles.taxRegimeDesc.copyWith(
                    fontSize: 12.5,
                    height: 1.5,
                  )
                : AppTextStyles.taxRegimeDesc,
          ),
          SizedBox(height: compact ? AppSpacing.sp8 + 2 : AppSpacing.sp12),
          Wrap(
            spacing: compact ? AppSpacing.sp4 + 2 : AppSpacing.sp8,
            runSpacing: compact ? AppSpacing.sp4 + 2 : AppSpacing.sp8,
            children: [
              for (final fact in facts) _FactPill(text: fact, compact: compact),
            ],
          ),
          if (objects != null) ...[
            SizedBox(height: compact ? AppSpacing.sp8 + 3 : AppSpacing.sp12),
            RegimeObjectSwitch(
              objects: objects,
              selectedIndex: objIndex,
              onChanged: onObjectChanged,
              compact: compact,
            ),
          ],
          SizedBox(height: compact ? AppSpacing.sp12 : AppSpacing.sp12 + 2),
          _MoreLink(url: item.moreUrl, compact: compact),
        ],
      ),
    );
  }
}

class _RateChip extends StatelessWidget {
  final String label;
  final bool orange;
  final bool compact;
  const _RateChip({
    required this.label,
    required this.orange,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sp8 + 2 : AppSpacing.sp12,
        vertical: compact ? AppSpacing.sp4 : AppSpacing.sp4 + 1,
      ),
      decoration: BoxDecoration(
        color: orange ? AppColors.onbOrangeSoft : AppColors.onbGreenSoft,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            (compact
                    ? AppTextStyles.taxRegimeChip.copyWith(fontSize: 11)
                    : AppTextStyles.taxRegimeChip)
                .copyWith(
                  color: orange ? AppColors.onbOrangeText : AppColors.onbGreen,
                ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  final bool active;
  final bool compact;
  const _CheckCircle({required this.active, required this.compact});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 21.0 : 24.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.onbGreen : Colors.transparent,
        border: Border.all(
          color: active ? AppColors.onbGreen : AppColors.onbLine,
          width: 1.5,
        ),
      ),
      child: active
          ? Icon(Icons.check_rounded, size: compact ? 12 : 14, color: Colors.white)
          : null,
    );
  }
}

class _FactPill extends StatelessWidget {
  final String text;
  final bool compact;
  const _FactPill({required this.text, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sp8 + 1 : AppSpacing.sp12 - 1,
        vertical: compact ? AppSpacing.sp4 : AppSpacing.sp4 + 1,
      ),
      decoration: BoxDecoration(
        color: AppColors.onbBg,
        border: Border.all(color: AppColors.onbLine),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        text,
        style: compact
            ? AppTextStyles.taxRegimeFact.copyWith(fontSize: 11)
            : AppTextStyles.taxRegimeFact,
      ),
    );
  }
}

class _MoreLink extends StatelessWidget {
  final String url;
  final bool compact;
  const _MoreLink({required this.url, required this.compact});

  // Ссылка на официальную страницу ФНС по режиму (см. moreUrl в
  // tax_regimes_meta.dart, адреса проверены вручную). Ошибка открытия не
  // критична для основного флоу (выбор/сохранение режима), поэтому не
  // всплывает дальше SnackBar.
  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(url);
    final ok = await canLaunchUrl(uri) && await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      rootMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('Не удалось открыть ссылку'),
          backgroundColor: AppColors.onbDanger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            compact ? 'Подробнее →' : 'Подробнее о режиме →',
            style: compact
                ? AppTextStyles.taxRegimeMoreLink.copyWith(fontSize: 12)
                : AppTextStyles.taxRegimeMoreLink,
          ),
        ],
      ),
    );
  }
}
