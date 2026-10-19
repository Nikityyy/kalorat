import 'dart:js_interop';

/// Defined in `web/haptics.js`.
@JS('kaloratHaptic')
external void _haptic(int kind);

void _play(int kind) {
  try {
    _haptic(kind);
  } catch (_) {
    // No haptics on this browser.
  }
}

/// Defined in `web/haptics_test.js`.
@JS('kaloratHapticsTest')
external void _openTest(String labelsJson);

void openTest(String labelsJson) {
  try {
    _openTest(labelsJson);
  } catch (_) {}
}

void tick() => _play(0);

void selection() => _play(1);

void confirm() => _play(2);
