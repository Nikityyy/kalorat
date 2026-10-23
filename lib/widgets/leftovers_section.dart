import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../extensions/l10n_extension.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/haptics.dart';

/// Most leftover photos one analysis takes.
const maxLeftoverPhotos = 3;

/// A photo of what was left on the plate, with its bytes for the thumbnail.
/// Used for one analysis only, never stored.
class LeftoverPhoto {
  final String path;
  final Uint8List bytes;
  const LeftoverPhoto(this.path, this.bytes);
}

/// Takes or picks a photo of the leftovers; null when cancelled.
Future<LeftoverPhoto?> pickLeftoverPhoto(ImageSource source) async {
  Haptics.tick();
  final image = await ImagePicker().pickImage(
    source: source,
    imageQuality: 70,
    maxWidth: 1600,
    maxHeight: 1600,
    requestFullMetadata: false,
  );
  if (image == null) return null;
  return LeftoverPhoto(image.path, await image.readAsBytes());
}

/// "Subtract leftovers": buttons to take or pick photos of what is left on
/// the plate, then their thumbnails. The photos live in the parent, which
/// adds the result of [pickLeftoverPhoto] to them.
class LeftoversSection extends StatelessWidget {
  final List<LeftoverPhoto> leftovers;
  final void Function(ImageSource source) onAdd;
  final void Function(LeftoverPhoto leftover) onRemove;

  /// Without the title, for a place that already asks the question.
  final bool showTitle;

  const LeftoversSection({
    super.key,
    required this.leftovers,
    required this.onAdd,
    required this.onRemove,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final children = <Widget>[
      if (showTitle) ...[
        Text(
          l10n.retryLeftoversTitle,
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
      ],
      Text(l10n.retryLeftoversHint, style: AppTypography.secondary),
      const SizedBox(height: 12),
    ];
    if (leftovers.isEmpty) {
      children.add(
        Row(
          children: [
            Expanded(
              child: _LeftoverButton(
                icon: Icons.photo_camera_outlined,
                label: l10n.retryLeftoversCamera,
                onTap: () => onAdd(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LeftoverButton(
                icon: Icons.photo_library_outlined,
                label: l10n.retryLeftoversGallery,
                onTap: () => onAdd(ImageSource.gallery),
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
            for (final leftover in leftovers) ...[
              _LeftoverThumb(
                bytes: leftover.bytes,
                removeLabel: l10n.retryLeftoverRemove,
                onRemove: () {
                  Haptics.tick();
                  onRemove(leftover);
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
                    l10n.retryLeftoversCount(leftovers.length),
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l10n.retryLeftoversCountHint,
                    style: AppTypography.secondary,
                  ),
                  if (leftovers.length < maxLeftoverPhotos)
                    TextButton(
                      onPressed: () => onAdd(ImageSource.camera),
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
