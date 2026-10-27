import 'package:flutter/material.dart';
import '../../extensions/l10n_extension.dart';
import '../../models/models.dart';
import '../../services/barcode/food_product.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../utils/nutrition_units.dart';
import '../../widgets/common/adaptive.dart';
import '../../widgets/common/warm_up.dart';

/// What the user chose in the quick log sheet.
sealed class QuickLogResult {
  const QuickLogResult();
}

/// Log [meal] again as it was.
class QuickLogRepeat extends QuickLogResult {
  final MealModel meal;

  const QuickLogRepeat(this.meal);
}

/// Estimate a meal from the user's [text].
class QuickLogDescribe extends QuickLogResult {
  final String text;

  const QuickLogDescribe(this.text);
}

/// Log [product], found in Open Food Facts by its name.
class QuickLogProduct extends QuickLogResult {
  final FoodProduct product;

  const QuickLogProduct(this.product);
}

/// Searches products by name; null when the search failed.
typedef ProductSearch = Future<List<FoodProduct>?> Function(String query);

/// Logs a meal without a photo: describe it, find a product by its name
/// with [search], or pick one eaten before. Returns null when dismissed.
Future<QuickLogResult?> showQuickLogSheet(
  BuildContext context, {
  required List<MealModel> recent,
  ProductSearch? search,
}) => showModalBottomSheet<QuickLogResult>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _QuickLogSheet(recent: recent, search: search),
);

/// The sheet as [showQuickLogSheet] shows it, for [WarmUp.run].
Widget quickLogSheetWarmUp(BuildContext context) =>
    const WarmUpSheet(child: _QuickLogSheet(recent: []));

class _QuickLogSheet extends StatefulWidget {
  final List<MealModel> recent;
  final ProductSearch? search;

  const _QuickLogSheet({required this.recent, this.search});

  @override
  State<_QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends State<_QuickLogSheet> {
  final TextEditingController _controller = TextEditingController();
  // No autofocus: the textarea jumps off screen on mobile when it grabs focus
  // while the sheet is still animating in.
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _describe() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, QuickLogDescribe(text));
  }

  // The product search: running, its results, or that it failed.
  bool _searching = false;
  List<FoodProduct>? _found;
  bool _searchFailed = false;

  /// Only when asked: Open Food Facts wants no search while typing.
  Future<void> _searchProducts() async {
    final search = widget.search;
    final text = _controller.text.trim();
    if (search == null || text.length < 2 || _searching) return;
    _focusNode.unfocus();
    setState(() {
      _searching = true;
      _searchFailed = false;
    });
    final found = await search(text);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _found = found;
      _searchFailed = found == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.quickLogTitle,
              style: AppTypography.displayMedium.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              magnifierConfiguration: fieldMagnifier,
              focusNode: _focusNode,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: l10n.quickLogHint,
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.text.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: value.text.trim().isEmpty ? null : _describe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    disabledBackgroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.mealContextAnalyze,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            if (widget.search != null)
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: value.text.trim().length < 2 || _searching
                          ? null
                          : _searchProducts,
                      icon: _searching
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(Icons.search, size: 20),
                      label: Text(l10n.offSearch),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),
            if (_searchFailed || _found != null) ...[
              const SizedBox(height: 16),
              _SectionLabel(l10n.offSearchResults),
              const SizedBox(height: 4),
              if (_searchFailed || _found!.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _searchFailed ? l10n.offSearchFailed : l10n.offSearchNone,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      for (final product in _found!)
                        _ProductRow(
                          product: product,
                          onTap: () =>
                              Navigator.pop(context, QuickLogProduct(product)),
                        ),
                    ],
                  ),
                ),
            ] else if (widget.recent.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionLabel(l10n.quickLogRecent),
              const SizedBox(height: 4),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    for (final meal in widget.recent)
                      _RecentMealRow(
                        meal: meal,
                        onTap: () =>
                            Navigator.pop(context, QuickLogRepeat(meal)),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: AppTypography.labelLarge.copyWith(
      fontSize: 10,
      letterSpacing: 1.0,
      color: AppColors.text.withValues(alpha: 0.5),
    ),
  );
}

/// A product from the search: its name, brand and energy per 100 g or ml.
class _ProductRow extends StatelessWidget {
  final FoodProduct product;
  final VoidCallback onTap;

  const _ProductRow({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kcal = product.caloriesPer100?.round();
    final per100 = kcal == null
        ? null
        : product.unit == portionUnitMl
        ? l10n.offPer100Ml(kcal)
        : l10n.componentPer100(kcal);
    final details = [?product.brand, ?per100].join(' · ');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (details.isNotEmpty)
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.secondary,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.add_circle_outline,
                size: 22,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentMealRow extends StatelessWidget {
  final MealModel meal;
  final VoidCallback onTap;

  const _RecentMealRow({required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: [
            Expanded(
              child: Text(
                meal.mealName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${meal.calories.round()} ${l10n.kcal}',
              style: AppTypography.dataMedium.copyWith(
                fontSize: 12,
                color: AppColors.text.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.add_circle_outline, size: 22, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
