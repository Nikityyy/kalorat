import 'package:flutter/widgets.dart';

/// Press feedback for tappable surfaces: a quick scale to 98% with a short
/// opacity dip that eases back on release. It only listens to raw pointer
/// events, so taps, drags and hit areas are exactly those of [child].
class Pressable extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const Pressable({super.key, required this.child, this.enabled = true});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  static const _pressedScale = 0.98;
  static const _pressedOpacity = 0.94;

  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    final down = _pressed && widget.enabled;
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: down && animate ? _pressedScale : 1,
        duration: Duration(milliseconds: down ? 70 : 220),
        curve: down ? Curves.easeOut : Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: down && animate ? _pressedOpacity : 1,
          duration: Duration(milliseconds: down ? 70 : 180),
          child: widget.child,
        ),
      ),
    );
  }
}
