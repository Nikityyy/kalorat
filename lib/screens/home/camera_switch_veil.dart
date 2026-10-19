import 'dart:typed_data';

import 'package:flutter/material.dart';

/// The last picture of the camera, blurred, over the preview while the
/// camera switches between back and front. Once the other camera plays
/// ([reveal]), it fades into the live preview, which reads as the picture
/// coming into focus, then [onDone] is called.
///
/// [snapshot] comes blurred and darkened already (see
/// `kaloratPreviewSnapshot` in web/camera_devices.js), so no filter runs on
/// any frame of the fade.
class CameraSwitchVeil extends StatefulWidget {
  final Uint8List snapshot;

  /// The picture came from the front camera, whose preview is mirrored.
  final bool mirrored;
  final bool reveal;
  final VoidCallback onDone;

  const CameraSwitchVeil({
    super.key,
    required this.snapshot,
    required this.mirrored,
    required this.reveal,
    required this.onDone,
  });

  @override
  State<CameraSwitchVeil> createState() => _CameraSwitchVeilState();
}

class _CameraSwitchVeilState extends State<CameraSwitchVeil>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..addStatusListener(_onStatus);
  late final Animation<double> _opacity = ReverseAnimation(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
  );

  @override
  void initState() {
    super.initState();
    if (widget.reveal) _startReveal();
  }

  @override
  void didUpdateWidget(CameraSwitchVeil old) {
    super.didUpdateWidget(old);
    if (widget.reveal && !old.reveal) _startReveal();
  }

  Future<void> _startReveal() async {
    // The new preview needs a frame or two before it shows a picture.
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (mounted) _controller.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: _opacity,
        child: ColoredBox(
          color: Colors.black,
          child: SizedBox.expand(
            child: Transform.flip(
              flipX: widget.mirrored,
              child: Image.memory(
                widget.snapshot,
                fit: BoxFit.cover,
                // Soft and darkened already; plain bilinear scaling keeps
                // it soft without an extra shader.
                filterQuality: FilterQuality.low,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
