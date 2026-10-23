import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../extensions/l10n_extension.dart';
import '../../services/barcode/barcode_preference.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../widgets/barcode_switch_tile.dart';
import '../../widgets/common/adaptive.dart';
import '../../widgets/common/warm_up.dart';
import '../../widgets/leftovers_section.dart';

/// What the user asked for in the retry sheet.
class RetryRequest {
  /// The note for the new analysis; null when empty.
  final String? note;

  /// Photos of what was left on the plate; the new analysis counts only
  /// what was eaten. Used for this analysis only, never stored.
  final List<String> leftoverPaths;

  const RetryRequest(this.note, {this.leftoverPaths = const []});
}

/// Asks what to tell the AI before a meal is analysed again. Null when the
/// sheet is closed without retrying. For a meal logged from a barcode
/// ([barcodeProduct] is its product name), a switch keeps the product's
/// values instead; while it is on there is nothing to retry.
Future<RetryRequest?> showRetrySheet(
  BuildContext context, {
  String? initialNote,
  String? barcodeProduct,
  required bool hasPhotos,
}) => showModalBottomSheet<RetryRequest>(
  context: context,
  isScrollControlled: true,
  isDismissible: true,
  builder: (_) => _RetrySheet(
    initialNote: initialNote,
    barcodeProduct: barcodeProduct,
    hasPhotos: hasPhotos,
  ),
);

/// The sheet as [showRetrySheet] shows it for a meal with photos, for
/// [WarmUp.run].
Widget retrySheetWarmUp(BuildContext context) =>
    const WarmUpSheet(child: _RetrySheet(hasPhotos: true));

class _RetrySheet extends StatefulWidget {
  final String? initialNote;
  final String? barcodeProduct;
  final bool hasPhotos;

  const _RetrySheet({
    this.initialNote,
    this.barcodeProduct,
    required this.hasPhotos,
  });

  @override
  State<_RetrySheet> createState() => _RetrySheetState();
}

class _RetrySheetState extends State<_RetrySheet> {
  late final TextEditingController _note = TextEditingController(
    text: widget.initialNote,
  );
  late bool _useBarcode =
      widget.barcodeProduct != null && BarcodePreference.useBarcode;
  final List<LeftoverPhoto> _leftovers = [];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _retry() {
    final text = _note.text.trim();
    Navigator.pop(
      context,
      RetryRequest(
        text.isNotEmpty ? text : null,
        leftoverPaths: [for (final leftover in _leftovers) leftover.path],
      ),
    );
  }

  Future<void> _addLeftover(ImageSource source) async {
    final leftover = await pickLeftoverPhoto(source);
    if (leftover == null ||
        !mounted ||
        _leftovers.length >= maxLeftoverPhotos) {
      return;
    }
    setState(() => _leftovers.add(leftover));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final product = widget.barcodeProduct;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
    );
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
              l10n.retrySheetTitle,
              style: AppTypography.displayMedium.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.retrySheetSubtitle,
              style: AppTypography.bodySmall.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 12),
            if (product != null) ...[
              BarcodeSwitchTile(
                productName: product,
                value: _useBarcode,
                onHint: l10n.barcodeRetryHint,
                onChanged: (value) {
                  setState(() => _useBarcode = value);
                  BarcodePreference.setUseBarcode(value);
                },
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _note,
              magnifierConfiguration: fieldMagnifier,
              enabled: !_useBarcode,
              maxLines: 3,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: l10n.retrySheetHint,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            // Leftovers are subtracted from the meal's photos, so there is
            // nothing to subtract from for a meal described in words.
            if (widget.hasPhotos && !_useBarcode) ...[
              const SizedBox(height: 20),
              LeftoversSection(
                leftovers: _leftovers,
                onAdd: _addLeftover,
                onRemove: (leftover) =>
                    setState(() => _leftovers.remove(leftover)),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.surface),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: shape,
                    ),
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(color: AppColors.text),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _note,
                    builder: (_, value, _) {
                      // Without a photo the note is the whole input.
                      final canRetry =
                          !_useBarcode &&
                          (widget.hasPhotos || value.text.trim().isNotEmpty);
                      return ElevatedButton(
                        onPressed: canRetry ? _retry : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: shape,
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.retrySheetAction,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
