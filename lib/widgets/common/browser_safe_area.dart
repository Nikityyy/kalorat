import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../utils/safe_area_stub.dart'
    if (dart.library.js_interop) '../../utils/safe_area_web.dart';

/// Hands the browser's safe-area insets (status bar, home indicator) to the
/// app as [MediaQueryData.padding], which Flutter's web engine leaves at 0.
/// Without them the tab bar sits on the iPhone's home indicator.
///
/// The page covers the whole screen (`viewport-fit=cover` in index.html), so
/// the status bar lies over the app. Its text is white there
/// (`black-translucent`), so the strip under it stays dark.
class BrowserSafeArea extends StatefulWidget {
  final Widget child;

  const BrowserSafeArea({super.key, required this.child});

  @override
  State<BrowserSafeArea> createState() => _BrowserSafeAreaState();
}

class _BrowserSafeAreaState extends State<BrowserSafeArea>
    with WidgetsBindingObserver {
  EdgeInsets _insets = browserSafeArea();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Rotation and the keyboard change the window; the insets may follow.
    final insets = browserSafeArea();
    if (insets != _insets) setState(() => _insets = insets);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (!kIsWeb ||
        _insets == EdgeInsets.zero ||
        media.viewPadding != EdgeInsets.zero) {
      return widget.child;
    }
    // As on a phone: the keyboard covers the bottom inset.
    final keyboard = media.viewInsets;
    final padding = EdgeInsets.fromLTRB(
      _insets.left,
      _insets.top,
      _insets.right,
      math.max(0, _insets.bottom - keyboard.bottom),
    );
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        Positioned.fill(
          child: MediaQuery(
            data: media.copyWith(viewPadding: _insets, padding: padding),
            child: widget.child,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _insets.top,
          child: const IgnorePointer(child: ColoredBox(color: Colors.black)),
        ),
      ],
    );
  }
}
