import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../utils/safe_area_stub.dart'
    if (dart.library.js_interop) '../../utils/safe_area_web.dart';

/// Hands the browser's safe-area insets (the iPhone's home indicator) to the
/// app as [MediaQueryData.padding], which Flutter's web engine leaves at 0.
/// Without them the tab bar sits on the home indicator. See
/// kaloratSafeArea in index.html for where they come from.
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
    // Always the same widgets, so the app below keeps its state whatever the
    // insets do.
    if (!kIsWeb ||
        _insets == EdgeInsets.zero ||
        media.viewPadding != EdgeInsets.zero) {
      return MediaQuery(data: media, child: widget.child);
    }
    // As on a phone: the keyboard covers the bottom inset.
    final padding = _insets.copyWith(
      bottom: math.max(0, _insets.bottom - media.viewInsets.bottom),
    );
    return MediaQuery(
      data: media.copyWith(viewPadding: _insets, padding: padding),
      child: widget.child,
    );
  }
}
