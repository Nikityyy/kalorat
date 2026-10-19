import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../extensions/l10n_extension.dart';
import '../services/photo_store.dart';
import '../widgets/app_toast.dart';

/// Saves a meal photo to the camera roll and says whether it worked. The web
/// cannot write to the camera roll; there the share sheet offers "Save Image".
Future<void> savePhotoToGallery(BuildContext context, String photo) async {
  final l10n = context.l10n;
  var saved = true;
  try {
    if (kIsWeb) {
      final bytes = await PhotoStore.instance.read(photo);
      if (bytes == null) throw StateError('Photo not found');
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'image/jpeg',
              name: 'kalorat_meal.jpg',
            ),
          ],
        ),
      );
    } else {
      await Gal.putImage(photo, album: 'Kalorat');
    }
  } catch (_) {
    saved = false;
  }
  if (!context.mounted) return;
  AppToast.show(
    context,
    saved ? l10n.saveToGallerySuccess : l10n.saveToGalleryError,
    kind: AppToastKind.info,
  );
}
