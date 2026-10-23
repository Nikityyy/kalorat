import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../extensions/l10n_extension.dart';
import '../../services/barcode/barcode_preference.dart';
import '../../services/barcode/food_product.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../widgets/barcode_switch_tile.dart';
import '../../widgets/common/adaptive.dart';
import '../../widgets/common/warm_up.dart';

/// What the user chose in the "Anything to add?" sheet.
class MealContextResult {
  /// The optional note about the meal; null when empty or skipped.
  final String? context;

  /// Analyse later instead of waiting for the result.
  final bool background;

  /// Log the product found in the photos instead of analysing them.
  final bool useBarcode;

  const MealContextResult({
    this.context,
    this.background = false,
    this.useBarcode = false,
  });
}

/// Asks for an optional note before a meal is analysed. Returns null when the
/// sheet is dismissed, which means no analysis. When [barcode] holds a
/// product read from the photos (it may arrive while the sheet is open), a
/// switch offers its values instead. Without [allowBackground] there is no
/// "in the background" (the analysis needs photos that are not kept).
Future<MealContextResult?> showMealContextSheet(
  BuildContext context, {
  String? initialText,
  ValueListenable<FoodProduct?>? barcode,
  bool allowBackground = true,
}) => showModalBottomSheet<MealContextResult>(
  context: context,
  isScrollControlled: true,
  isDismissible: true,
  builder: (_) => _MealContextSheet(
    initialText: initialText,
    barcode: barcode,
    allowBackground: allowBackground,
  ),
);

/// The sheet as [showMealContextSheet] shows it, for [WarmUp.run].
Widget mealContextSheetWarmUp(BuildContext context) =>
    const WarmUpSheet(child: _MealContextSheet());

class _MealContextSheet extends StatefulWidget {
  final String? initialText;
  final ValueListenable<FoodProduct?>? barcode;
  final bool allowBackground;

  const _MealContextSheet({
    this.initialText,
    this.barcode,
    this.allowBackground = true,
  });

  @override
  State<_MealContextSheet> createState() => _MealContextSheetState();
}

class _MealContextSheetState extends State<_MealContextSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );
  // No autofocus: the textarea jumps off screen on mobile when it grabs focus
  // while the sheet is still animating in.
  final FocusNode _focusNode = FocusNode();
  bool _useBarcode = BarcodePreference.useBarcode;

  FoodProduct? get _product => widget.barcode?.value;

  bool get _barcodeOn => _useBarcode && _product != null;

  @override
  void initState() {
    super.initState();
    widget.barcode?.addListener(_onBarcode);
  }

  void _onBarcode() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.barcode?.removeListener(_onBarcode);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit({bool background = false}) {
    final text = _controller.text.trim();
    Navigator.pop(
      context,
      MealContextResult(
        context: text.isNotEmpty ? text : null,
        background: background,
        useBarcode: _barcodeOn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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
              l10n.mealContextTitle,
              style: AppTypography.displayMedium.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 12),
            if (_product case final product?) ...[
              BarcodeSwitchTile(
                productName: product.displayName,
                value: _useBarcode,
                onChanged: (value) {
                  setState(() => _useBarcode = value);
                  BarcodePreference.setUseBarcode(value);
                },
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _controller,
              magnifierConfiguration: fieldMagnifier,
              // The note is for the analysis; a product brings its values.
              enabled: !_barcodeOn,
              // NO autofocus here — we use a FocusNode + postFrameCallback
              // to avoid the "textarea flies off screen" bug on mobile.
              focusNode: _focusNode,
              maxLines: 3,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: l10n.mealContextHint,
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
            const SizedBox(height: 16),
            if (!_barcodeOn) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(context, const MealContextResult()),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.surface),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                        ),
                      ),
                      child: Text(
                        l10n.mealContextSkip,
                        style: TextStyle(color: AppColors.text),
                      ),
                    ),
                  ),
                  if (widget.allowBackground) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _submit(background: true),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.surface),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          l10n.mealContextBackground,
                          style: TextStyle(color: AppColors.text),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _barcodeOn ? l10n.continueButton : l10n.mealContextAnalyze,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
