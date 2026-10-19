import 'dart:js_interop';

import 'package:flutter/widgets.dart';

/// Defined in `web/index.html`: the CSS safe-area insets as "top,right,bottom,left".
@JS('kaloratSafeArea')
external JSString _safeArea();

/// The screen edges the browser keeps for the status bar and the home
/// indicator. Flutter's web engine does not pass them on (its padding is 0).
EdgeInsets browserSafeArea() {
  try {
    final v = _safeArea().toDart.split(',').map(double.parse).toList();
    return EdgeInsets.fromLTRB(v[3], v[0], v[1], v[2]);
  } catch (_) {
    return EdgeInsets.zero;
  }
}
