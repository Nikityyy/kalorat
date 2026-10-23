import 'dart:typed_data';

import 'package:flutter/material.dart';

/// The last picture of the camera, blurred, over the preview while the
/// camera starts again: after a switch between back and front, or when the
/// camera tab comes back. With [fadeIn] it first fades in over the playing
/// preview, which reads as the picture going out of focus ([coverDuration]
/// long; the old camera must keep playing until then). Once the preview
/// shows a new frame ([reveal]), it fades into the live picture, which reads
/// as the picture coming into focus, then [onDone] is called.
///
/// [snapshot] comes blurred and darkened already (see
/// `kaloratPreviewSnapshot` in web/camera_devices.js), so no filter runs on
/// any frame of the fade.
class CameraSwitchVeil extends StatefulWidget {
  final Uint8List snapshot;

  /// The picture came from the front camera, whose preview is mirrored.
  final bool mirrored;
  final bool fadeIn;
  final bool reveal;
  final VoidCallback onDone;

  /// How long the fade in takes.
  static const coverDuration = Duration(milliseconds: 260);

  const CameraSwitchVeil({
    super.key,
    required this.snapshot,
    required this.mirrored,
    required this.reveal,
    required this.onDone,
    this.fadeIn = false,
  });

  @override
  State<CameraSwitchVeil> createState() => _CameraSwitchVeilState();
}

class _CameraSwitchVeilState extends State<CameraSwitchVeil>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..addStatusListener(_onStatus);
  // 0 → 1 while the veil fades in; stands at 1 without [fadeIn].
  late final AnimationController _cover = AnimationController(
    vsync: this,
    duration: CameraSwitchVeil.coverDuration,
    value: widget.fadeIn ? 0 : 1,
  );
  late final Animation<double> _coverOpacity = CurvedAnimation(
    parent: _cover,
    curve: Curves.easeOutCubic,
  );
  late final Animation<double> _opacity = ReverseAnimation(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
  );

  @override
  void initState() {
    super.initState();
    if (widget.fadeIn) _cover.forward();
    if (widget.reveal) _startReveal();
  }

  @override
  void didUpdateWidget(CameraSwitchVeil old) {
    super.didUpdateWidget(old);
    if (widget.reveal && !old.reveal) _startReveal();
  }

  void _startReveal() => _controller.forward();

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    _cover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_coverOpacity, _opacity]),
        builder: (context, child) => Opacity(
          opacity: _coverOpacity.value * _opacity.value,
          child: child,
        ),
        child: SizedBox.expand(
          child: Transform.flip(
            flipX: widget.mirrored,
            child: Image.memory(
              widget.snapshot,
              fit: BoxFit.cover,
              // Soft and darkened already; plain bilinear scaling keeps it
              // soft without an extra shader.
              filterQuality: FilterQuality.low,
              gaplessPlayback: true,
            ),
          ),
        ),
      ),
    );
  }
}
