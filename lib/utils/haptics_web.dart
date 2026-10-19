import 'dart:js_interop';

/// Defined in `web/haptics.js`.
@JS('kaloratHaptic')
external void _haptic(int kind);

@JS('kaloratHapticsInit')
external void _init();

void init() {
  try {
    _init();
  } catch (_) {
    // haptics.js did not load.
  }
}

void _play(int kind) {
  try {
    _haptic(kind);
  } catch (_) {
    // No haptics on this browser.
  }
}

void tick() => _play(0);

void selection() => _play(1);

void confirm() => _play(2);
