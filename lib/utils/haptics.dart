import 'haptics_stub.dart'
    if (dart.library.js_interop) 'haptics_web.dart'
    as platform;

/// Short physical feedback for taps. Call it from the tap handler itself: the
/// web build (iOS Safari) only plays haptics during a user gesture.
class Haptics {
  const Haptics._();

  /// A button, tab or card was pressed.
  static void tick() => platform.tick();

  /// A picker or wheel moved to the next value.
  static void selection() => platform.selection();

  /// The web build's haptics test panel (web/haptics_test.js), with its
  /// texts as JSON.
  static void openTest(String labelsJson) => platform.openTest(labelsJson);

  /// An action completed (photo captured).
  static void confirm() => platform.confirm();
}
