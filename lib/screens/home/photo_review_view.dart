import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:image_picker/image_picker.dart';
import '../../extensions/l10n_extension.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../utils/haptics.dart';
import '../../widgets/common/segmented_tabs.dart';
import '../../widgets/inputs/action_button.dart';
import '../../widgets/leftovers_section.dart';

/// The taken photos in a grid, with the choices to discard, add more or start
/// the analysis. Photos of what was left on the plate can be added below the
/// grid ([onAddLeftover]); the analysis then counts only what was eaten.
class PhotoReviewView extends StatelessWidget {
  /// Links a photo in the grid to the same photo in the full-screen viewer.
  static Object heroTag(String photo) => 'review-photo-$photo';

  final List<String> photos;
  final bool isAnalyzing;
  final ImageProvider Function(String photo) imageFor;
  final void Function(int index) onOpen;
  final Future<void> Function(int index) onRemove;
  final void Function(int from, int to) onReorder;
  final VoidCallback onDiscard;
  final VoidCallback onAddPhoto;
  final VoidCallback onAnalyze;

  /// "Finished it all?" Answering "no" asks for photos of the leftovers.
  /// A null [onLeftoversChanged] leaves the question out (leftovers need the
  /// analysis to run now).
  final bool hasLeftovers;
  final ValueChanged<bool>? onLeftoversChanged;
  final List<LeftoverPhoto> leftovers;
  final void Function(ImageSource source)? onAddLeftover;
  final void Function(LeftoverPhoto leftover)? onRemoveLeftover;

  /// False while the analysis would still be missing the leftover photos.
  final bool canAnalyze;

  const PhotoReviewView({
    super.key,
    required this.photos,
    required this.isAnalyzing,
    required this.imageFor,
    required this.onOpen,
    required this.onRemove,
    required this.onReorder,
    required this.onDiscard,
    required this.onAddPhoto,
    required this.onAnalyze,
    this.hasLeftovers = false,
    this.onLeftoversChanged,
    this.leftovers = const [],
    this.onAddLeftover,
    this.onRemoveLeftover,
    this.canAnalyze = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onLeftoversChanged = this.onLeftoversChanged;

    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            l10n.reviewPhotos,
            style: AppTypography.displayMedium.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 16),

          if (photos.length > 1) ...[
            Text(
              l10n.reorderPhotosHint,
              style: AppTypography.meta,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReorderableGrid(
                    photos: photos,
                    imageFor: imageFor,
                    onOpen: onOpen,
                    onRemove: onRemove,
                    onReorder: onReorder,
                  ),
                  if (onLeftoversChanged != null) ...[
                    const SizedBox(height: 28),
                    Text(
                      l10n.leftoversQuestion,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedTabs(
                      labels: [l10n.leftoversNone, l10n.leftoversSome],
                      selected: hasLeftovers ? 1 : 0,
                      onChanged: (i) => onLeftoversChanged(i == 1),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: hasLeftovers
                          ? Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: LeftoversSection(
                                showTitle: false,
                                leftovers: leftovers,
                                onAdd: onAddLeftover ?? (_) {},
                                onRemove: onRemoveLeftover ?? (_) {},
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.borderRadius),
              ),
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDiscard,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.surface),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius,
                              ),
                            ),
                          ),
                          child: Text(
                            l10n.discard,
                            style: TextStyle(color: AppColors.text),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onAddPhoto,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius,
                              ),
                            ),
                          ),
                          child: Text(
                            l10n.addPhoto,
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Dimmed until the leftovers have their photo.
                  AnimatedOpacity(
                    opacity: canAnalyze ? 1 : 0.4,
                    duration: const Duration(milliseconds: 160),
                    child: ActionButton(
                      text: l10n.startAnalysis,
                      isLoading: isAnalyzing,
                      onPressed: canAnalyze ? onAnalyze : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The photos two by two. Holding one lifts it; dragging it moves the others
/// out of its way, like the home screen's icons. The first one is the cover.
class _ReorderableGrid extends StatefulWidget {
  final List<String> photos;
  final ImageProvider Function(String photo) imageFor;
  final void Function(int index) onOpen;
  final Future<void> Function(int index) onRemove;
  final void Function(int from, int to) onReorder;

  const _ReorderableGrid({
    required this.photos,
    required this.imageFor,
    required this.onOpen,
    required this.onRemove,
    required this.onReorder,
  });

  @override
  State<_ReorderableGrid> createState() => _ReorderableGridState();
}

class _ReorderableGridState extends State<_ReorderableGrid> {
  static const _columns = 2;
  static const _gap = 16.0;
  static const _aspect = 0.8;

  String? _dragged;
  Offset _dragStart = Offset.zero;
  Offset _dragOffset = Offset.zero;

  void _move(int from, int to) {
    if (from == to) return;
    Haptics.selection();
    widget.onReorder(from, to);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final photos = widget.photos;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = (constraints.maxWidth - _gap * (_columns - 1)) / _columns;
        final cellH = cellW / _aspect;
        final rows = (photos.length / _columns).ceil();
        Offset slot(int i) => Offset(
          (i % _columns) * (cellW + _gap),
          (i ~/ _columns) * (cellH + _gap),
        );
        int slotAt(Offset center) {
          final col = (center.dx / (cellW + _gap)).floor().clamp(
            0,
            _columns - 1,
          );
          final row = (center.dy / (cellH + _gap)).floor().clamp(0, rows - 1);
          return (row * _columns + col).clamp(0, photos.length - 1);
        }

        Widget cell(int i) {
          final photo = photos[i];
          final dragging = photo == _dragged;
          final at = dragging ? _dragStart + _dragOffset : slot(i);
          return AnimatedPositioned(
            key: ValueKey(photo),
            duration: dragging
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            left: at.dx,
            top: at.dy,
            width: cellW,
            height: cellH,
            child: Semantics(
              customSemanticsActions: {
                if (i > 0)
                  CustomSemanticsAction(label: l10n.movePhotoEarlier): () =>
                      _move(i, i - 1),
                if (i < photos.length - 1)
                  CustomSemanticsAction(label: l10n.movePhotoLater): () =>
                      _move(i, i + 1),
              },
              child: GestureDetector(
                onTap: () => widget.onOpen(i),
                onLongPressStart: (_) {
                  Haptics.tick();
                  setState(() {
                    _dragged = photo;
                    _dragStart = slot(i);
                    _dragOffset = Offset.zero;
                  });
                },
                onLongPressMoveUpdate: (d) {
                  setState(() => _dragOffset = d.offsetFromOrigin);
                  final from = photos.indexOf(photo);
                  final center =
                      _dragStart + _dragOffset + Offset(cellW / 2, cellH / 2);
                  _move(from, slotAt(center));
                },
                onLongPressEnd: (_) => setState(() => _dragged = null),
                onLongPressCancel: () => setState(() => _dragged = null),
                child: AnimatedScale(
                  scale: dragging ? 1.05 : 1,
                  duration: const Duration(milliseconds: 160),
                  child: _PhotoTile(
                    image: widget.imageFor(photo),
                    heroTag: PhotoReviewView.heroTag(photo),
                    cover: i == 0 && photos.length > 1,
                    lifted: dragging,
                    onRemove: () => widget.onRemove(i),
                  ),
                ),
              ),
            ),
          );
        }

        // The lifted photo is painted last, above the others.
        final order = [
          for (var i = 0; i < photos.length; i++)
            if (photos[i] != _dragged) i,
          for (var i = 0; i < photos.length; i++)
            if (photos[i] == _dragged) i,
        ];
        return SizedBox(
          height: rows * cellH + (rows - 1) * _gap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [for (final i in order) cell(i)],
          ),
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final ImageProvider image;
  final Object heroTag;
  final bool cover;
  final bool lifted;
  final VoidCallback onRemove;

  const _PhotoTile({
    required this.image,
    required this.heroTag,
    required this.cover,
    required this.lifted,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(
                color: lifted ? AppColors.primary : AppColors.border,
                width: lifted ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              child: Hero(
                tag: heroTag,
                child: Image(image: image, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        if (cover)
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
              child: Text(
                l10n.coverPhoto,
                style: AppTypography.meta.copyWith(color: Colors.white),
              ),
            ),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: Semantics(
            button: true,
            label: l10n.delete,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              child: Container(
                // 16px icon in a 44px touch target
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
