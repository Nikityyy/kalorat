import 'dart:js_interop';

/// Defined in `web/index.html`.
@JS('kaloratHideSplash')
external void _hideSplash();

void hideSplash() {
  try {
    _hideSplash();
  } catch (_) {
    // index.html also removes the splash on its own after a timeout.
  }
}
