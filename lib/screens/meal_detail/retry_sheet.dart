import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../extensions/l10n_extension.dart';
import '../../services/barcode/barcode_preference.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../utils/haptics.dart';
import '../../widgets/barcode_switch_tile.dart';
import '../../widgets/common/adaptive.dart';
import '../../widgets/common/warm_up.dart';

/// What the user asked for in the retry sheet.
class RetryRequest {
  /// The note for the new analysis; null when empty.
  final String? note;

  /// Photos of what was left on the plate; the new analysis counts only
  /// what was eaten. Used for this analysis only, never stored.
  final List<String> leftoverPaths;

  const RetryRequest(this.note, {this.leftoverPaths = const []});
}

/// A photo of the leftovers, with its bytes for the thumbnail.
class _Leftover {
  final String path;
  final Uint8List bytes;
  const _Leftover(this.path, this.bytes);
}

const _maxLeftovers = 3;

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
  final List<_Leftover> _leftovers = [];

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
    Haptics.tick();
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
      maxHeight: 1600,
      requestFullMetadata: false,
    );
    if (image == null || !mounted) return;
    final bytes = await image.readAsBytes();
    if (!mounted || _leftovers.length >= _maxLeftovers) return;
    setState(() => _leftovers.add(_Leftover(image.path, bytes)));
  }

  Widget _leftoverSection() {
    final l10n = context.l10n;
    final children = <Widget>[
      Text(
        l10n.retryLeftoversTitle,
        style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 2),
      Text(l10n.retryLeftoversHint, style: AppTypography.secondary),
      const SizedBox(height: 12),
    ];
    if (_leftovers.isEmpty) {
      children.add(
        Row(
          children: [
            Expanded(
              child: _LeftoverButton(
                icon: Icons.photo_camera_outlined,
                label: l10n.retryLeftoversCamera,
                onTap: () => _addLeftover(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LeftoverButton(
                icon: Icons.photo_library_outlined,
                label: l10n.retryLeftoversGallery,
                onTap: () => _addLeftover(ImageSource.gallery),
              ),
            ),
          ],
        ),
      );
    } else {
      children.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final leftover in _leftovers) ...[
              _LeftoverThumb(
                bytes: leftover.bytes,
                removeLabel: l10n.retryLeftoverRemove,
                onRemove: () {
                  Haptics.tick();
                  setState(() => _leftovers.remove(leftover));
                },
              ),
              const SizedBox(width: 8),
            ],
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.retryLeftoversCount(_leftovers.length),
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l10n.retryLeftoversCountHint,
                    style: AppTypography.secondary,
                  ),
                  if (_leftovers.length < _maxLeftovers)
                    TextButton(
                      onPressed: () => _addLeftover(ImageSource.camera),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        alignment: Alignment.centerLeft,
                      ),
                      child: Text(
                        l10n.retryLeftoversAddMore,
                        style: AppTypography.secondary.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
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
              _leftoverSection(),
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

class _LeftoverButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LeftoverButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 88,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.secondary.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeftoverThumb extends StatelessWidget {
  final Uint8List bytes;
  final String removeLabel;
  final VoidCallback onRemove;

  const _LeftoverThumb({
    required this.bytes,
    required this.removeLabel,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                cacheWidth: (72 * dpr).round(),
                gaplessPlayback: true,
              ),
            ),
          ),
          Positioned(
            top: -10,
            right: -10,
            child: Semantics(
              button: true,
              label: removeLabel,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.deepSpaceBlack.withValues(alpha: 0.72),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.pureWhite,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
