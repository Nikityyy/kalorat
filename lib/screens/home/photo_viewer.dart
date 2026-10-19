import 'package:flutter/material.dart';

import '../../extensions/l10n_extension.dart';
import '../../utils/haptics.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';

/// Full-screen view of a meal's photos, like the system photo viewer: swipe
/// between them, pinch or double-tap to zoom, drag down to close. The photo
/// grows out of the tapped one when [heroTag] names it.
///
/// Returns the index of the photo shown when the viewer closed.
Future<int?> showPhotoViewer(
  BuildContext context, {
  required List<ImageProvider> images,
  int initialIndex = 0,
  Object Function(int index)? heroTag,
  void Function(int index)? onSave,
  Future<void> Function(int index)? onDelete,
}) {
  return Navigator.of(context).push<int>(
    PageRouteBuilder<int>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => _PhotoViewer(
        images: images,
        initialIndex: initialIndex.clamp(0, images.length - 1),
        heroTag: heroTag,
        onSave: onSave,
        onDelete: onDelete,
      ),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _PhotoViewer extends StatefulWidget {
  final List<ImageProvider> images;
  final int initialIndex;
  final Object Function(int index)? heroTag;
  final void Function(int index)? onSave;
  final Future<void> Function(int index)? onDelete;

  const _PhotoViewer({
    required this.images,
    required this.initialIndex,
    this.heroTag,
    this.onSave,
    this.onDelete,
  });

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer>
    with SingleTickerProviderStateMixin {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;
  final _zoom = TransformationController();
  late final AnimationController _zoomAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(() => _zoom.value = _zoomTween!.evaluate(_zoomAnimation));
  Matrix4Tween? _zoomTween;
  Offset _doubleTapAt = Offset.zero;
  bool _zoomed = false;
  bool _chrome = true;

  // Drag down to close: how far the photo has been pulled.
  double _pull = 0;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(() {
      final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;
      if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    _zoom.dispose();
    _zoomAnimation.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop(_index);

  void _animateZoomTo(Matrix4 target) {
    _zoomTween = Matrix4Tween(begin: _zoom.value, end: target);
    _zoomAnimation.forward(from: 0);
  }

  void _toggleZoom() {
    if (_zoomed) {
      _animateZoomTo(Matrix4.identity());
      return;
    }
    const scale = 2.5;
    final p = _doubleTapAt;
    _animateZoomTo(
      Matrix4.identity()
        ..translateByDouble(-p.dx * (scale - 1), -p.dy * (scale - 1), 0, 1)
        ..scaleByDouble(scale, scale, 1, 1),
    );
  }

  void _onPageChanged(int i) {
    Haptics.selection();
    _zoom.value = Matrix4.identity();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final media = MediaQuery.of(context);
    final count = widget.images.length;
    final fade = (1 - _pull.abs() / 400).clamp(0.0, 1.0);

    Widget photo(int i) {
      Widget image = Image(
        image: widget.images[i],
        fit: BoxFit.contain,
        gaplessPlayback: true,
      );
      final tag = widget.heroTag?.call(i);
      if (tag != null) image = Hero(tag: tag, child: image);
      return InteractiveViewer(
        transformationController: i == _index ? _zoom : null,
        minScale: 1,
        maxScale: 4,
        // Unzoomed, a pan belongs to the pages and to drag-to-close.
        panEnabled: _zoomed,
        child: SizedBox.expand(child: image),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: fade),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _chrome = !_chrome),
              onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
              onDoubleTap: _toggleZoom,
              onVerticalDragUpdate: _zoomed
                  ? null
                  : (d) => setState(() => _pull += d.delta.dy),
              onVerticalDragEnd: _zoomed
                  ? null
                  : (d) {
                      final v = d.primaryVelocity ?? 0;
                      if (_pull.abs() > 120 || v.abs() > 700) {
                        _close();
                      } else {
                        setState(() => _pull = 0);
                      }
                    },
              child: AnimatedContainer(
                duration: _pull == 0
                    ? const Duration(milliseconds: 200)
                    : Duration.zero,
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(0, _pull, 0),
                child: PageView.builder(
                  controller: _pages,
                  itemCount: count,
                  physics: _zoomed
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (_, i) => photo(i),
                ),
              ),
            ),
          ),
          // Close, the position, save and delete; a tap on the photo hides
          // them.
          Positioned(
            top: media.padding.top + 8,
            left: 16,
            right: 16,
            child: IgnorePointer(
              ignoring: !_chrome,
              child: AnimatedOpacity(
                opacity: _chrome && _pull == 0 ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                child: Row(
                  children: [
                    _ViewerButton(
                      icon: Icons.close,
                      tooltip: l10n.close,
                      onPressed: _close,
                    ),
                    const Spacer(),
                    if (count > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                        ),
                        child: Text(
                          '${_index + 1}/$count',
                          style: AppTypography.number(
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (widget.onSave != null)
                      _ViewerButton(
                        icon: Icons.download,
                        tooltip: l10n.saveToGallery,
                        onPressed: () => widget.onSave!(_index),
                      ),
                    if (widget.onDelete != null) ...[
                      const SizedBox(width: 10),
                      _ViewerButton(
                        icon: Icons.delete_outline,
                        tooltip: l10n.delete,
                        onPressed: () async {
                          final index = _index;
                          Navigator.of(context).pop(index);
                          await widget.onDelete!(index);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ViewerButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
