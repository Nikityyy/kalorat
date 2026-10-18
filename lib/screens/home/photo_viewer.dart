import 'package:flutter/material.dart';
import '../../extensions/l10n_extension.dart';
import '../../theme/app_colors.dart';

/// Full-screen view of one photo, with zoom, save and delete.
Future<void> showPhotoViewer(
  BuildContext context, {
  required ImageProvider image,
  required VoidCallback onSave,
  required Future<void> Function() onDelete,
}) {
  final l10n = context.l10n;
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (dialogContext) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(
                  child: Image(image: image, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PhotoViewerButton(
                    icon: Icons.close,
                    tooltip: l10n.close,
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                  Row(
                    children: [
                      _PhotoViewerButton(
                        icon: Icons.download,
                        tooltip: l10n.saveToGallery,
                        onPressed: onSave,
                      ),
                      const SizedBox(width: 10),
                      _PhotoViewerButton(
                        icon: Icons.delete_outline,
                        tooltip: l10n.discard,
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await onDelete();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PhotoViewerButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _PhotoViewerButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.46),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: AppColors.glacialWhite),
        ),
      ),
    );
  }
}
