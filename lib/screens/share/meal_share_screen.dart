import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../../extensions/l10n_extension.dart';
import '../../models/models.dart';
import '../../services/photo_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../utils/haptics.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/common/segmented_tabs.dart';
import '../../widgets/inputs/action_button.dart';
import 'meal_share_card.dart';

/// Opens the screen that turns [meal] into a picture for stories and
/// messages. [portionMultiplier] is the one the meal screen shows; the card
/// says what was eaten.
Future<void> showMealShare(
  BuildContext context, {
  required MealModel meal,
  required double portionMultiplier,
  int initialPhoto = 0,
}) => Navigator.push<void>(
  context,
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => MealShareScreen(
      meal: meal,
      portionMultiplier: portionMultiplier,
      initialPhoto: initialPhoto,
    ),
  ),
);

class MealShareScreen extends StatefulWidget {
  final MealModel meal;
  final double portionMultiplier;
  final int initialPhoto;

  const MealShareScreen({
    super.key,
    required this.meal,
    required this.portionMultiplier,
    this.initialPhoto = 0,
  });

  @override
  State<MealShareScreen> createState() => _MealShareScreenState();
}

class _MealShareScreenState extends State<MealShareScreen> {
  /// The picture is made at three times the card's size: 1080 x 1920.
  static const _pixelRatio = 3.0;

  /// The style used last stays for the next time.
  static ShareCardStyle _lastStyle = ShareCardStyle.photo;

  final GlobalKey _boundary = GlobalKey();
  late ShareCardStyle _style = _lastStyle;
  late int _photoIndex = widget.meal.photoPaths.isEmpty
      ? 0
      : widget.initialPhoto.clamp(0, widget.meal.photoPaths.length - 1);

  /// The picture of the card as shown, made ahead of the tap: browsers only
  /// open the share sheet from a tap that has not waited long.
  Future<Uint8List?>? _picture;
  int _generation = 0;
  bool _photoReady = false;

  List<String> get _photos => widget.meal.photoPaths;

  ImageProvider? _providerFor(int index) => _photos.isEmpty
      ? null
      : PhotoStore.instance.imageProvider(_photos[index]);

  @override
  void initState() {
    super.initState();
    // Decoding needs the screen's media settings, so it starts after the
    // first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadPhoto();
    });
  }

  /// Waits for the photo to be decoded, so the picture is never made with
  /// an empty card.
  Future<void> _loadPhoto() async {
    final generation = ++_generation;
    final provider = _providerFor(_photoIndex);
    setState(() {
      _photoReady = false;
      _picture = null;
    });
    await _decode([?provider, MealShareCard.wordmarkFor(_style)]);
    if (!mounted || generation != _generation) return;
    setState(() => _photoReady = true);
    _renderAfterPaint(generation);
  }

  /// Decodes the card's images, so they are drawn by the first frame the
  /// picture is made from. One that fails shows its fallback.
  Future<void> _decode(List<ImageProvider> images) async {
    for (final image in images) {
      try {
        await precacheImage(image, context);
      } catch (_) {}
      if (!mounted) return;
    }
  }

  void _renderAfterPaint(int generation) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) return;
      _picture = _render();
    });
  }

  Future<Uint8List?> _render() async {
    try {
      final boundary =
          _boundary.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: _pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Share card not rendered: $e');
      return null;
    }
  }

  Future<void> _setStyle(ShareCardStyle style) async {
    _lastStyle = style;
    final generation = ++_generation;
    // Its wordmark first: the card would change style without it, and a
    // picture made then would miss it.
    await _decode([MealShareCard.wordmarkFor(style)]);
    if (!mounted || generation != _generation) return;
    setState(() {
      _style = style;
      _picture = null;
    });
    _renderAfterPaint(generation);
  }

  void _setPhoto(int index) {
    if (index == _photoIndex) return;
    Haptics.selection();
    _photoIndex = index;
    _loadPhoto();
  }

  Future<Uint8List?> _pictureNow() async {
    var picture = _picture;
    if (picture == null) {
      // The style or photo changed a moment ago.
      await WidgetsBinding.instance.endOfFrame;
      picture = _picture ?? _render();
    }
    return picture;
  }

  Future<void> _share() async {
    final l10n = context.l10n;
    final bytes = await _pictureNow();
    if (!mounted) return;
    if (bytes == null) {
      _toast(l10n.shareFailed, AppToastKind.error);
      return;
    }
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'image/png',
              name: 'kalorat_meal.png',
            ),
          ],
          fileNameOverrides: const ['kalorat_meal.png'],
        ),
      );
    } catch (e) {
      debugPrint('Share failed: $e');
      if (mounted) _toast(l10n.shareFailed, AppToastKind.error);
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final bytes = await _pictureNow();
    if (!mounted) return;
    var saved = bytes != null;
    if (bytes != null) {
      try {
        await Gal.putImageBytes(
          bytes,
          album: 'Kalorat',
          name: 'kalorat_${widget.meal.id}',
        );
      } catch (_) {
        saved = false;
      }
    }
    if (!mounted) return;
    _toast(
      saved ? l10n.saveToGallerySuccess : l10n.saveToGalleryError,
      AppToastKind.info,
    );
  }

  void _toast(String message, AppToastKind kind) => AppToast.show(
    context,
    message,
    kind: kind,
    top: MediaQuery.paddingOf(context).top + 64,
  );

  ShareCardData _data() {
    final l10n = context.l10n;
    final meal = widget.meal;
    final m = widget.portionMultiplier;
    return ShareCardData(
      name: meal.mealName,
      calories: meal.calories * m,
      protein: meal.protein * m,
      carbs: meal.carbs * m,
      fats: meal.fats * m,
      language: Localizations.localeOf(context).languageCode,
      kcalLabel: l10n.kcal,
      proteinLabel: l10n.protein,
      carbsLabel: l10n.carbs,
      fatsLabel: l10n.fats,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final media = MediaQuery.of(context);
    final styles = ShareCardStyle.values;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Padding(
        padding: EdgeInsets.only(top: media.padding.top),
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: l10n.close,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Haptics.tick();
                        Navigator.pop(context);
                      },
                      child: SizedBox(
                        width: 64,
                        height: 56,
                        child: Icon(Icons.close, color: AppColors.text),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l10n.shareMealTitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.heading.copyWith(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 64),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Center(
                  child: AspectRatio(
                    aspectRatio:
                        MealShareCard.size.width / MealShareCard.size.height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius + 4,
                        ),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius + 3,
                        ),
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: RepaintBoundary(
                            key: _boundary,
                            child: MealShareCard(
                              data: _data(),
                              style: _style,
                              photo: _providerFor(_photoIndex),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_photos.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _photos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => _PhotoChoice(
                      image: PhotoStore.instance.imageProvider(
                        _photos[i],
                        cacheWidth: 144,
                      ),
                      selected: i == _photoIndex,
                      label: l10n.sharePhotoNumber(i + 1),
                      onTap: () => _setPhoto(i),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: SegmentedTabs(
                labels: [
                  l10n.shareStylePhoto,
                  l10n.shareStyleLight,
                  l10n.shareStyleDark,
                ],
                selected: styles.indexOf(_style),
                onChanged: (i) => _setStyle(styles[i]),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                media.padding.bottom + (kIsWeb ? 16 : 4),
              ),
              child: Column(
                children: [
                  ActionButton(
                    text: l10n.shareImageAction,
                    onPressed: _photoReady ? _share : null,
                  ),
                  // The web has no camera roll; its share sheet saves images.
                  if (!kIsWeb)
                    TextButton(
                      onPressed: _photoReady ? _save : null,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Text(
                        l10n.shareSaveAction,
                        style: AppTypography.body.copyWith(
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
      ),
    );
  }
}

/// A photo of the meal to choose for the card.
class _PhotoChoice extends StatelessWidget {
  final ImageProvider image;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _PhotoChoice({
    required this.image,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius - 3),
            child: Image(image: image, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
