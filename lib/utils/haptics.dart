import 'haptics_stub.dart'
    if (dart.library.js_interop) 'haptics_web.dart'
    as platform;

/// Short physical feedback for taps. Call it from the tap handler itself:
/// Android browsers only vibrate during a user gesture, and iPhones only tick
/// for a tap whose handler called it while the finger was down (see
/// web/haptics.js), on release, with one tick for every kind.
class Haptics {
  const Haptics._();

  /// Sets up the iPhone web haptics once the app has drawn its first frame.
  static void init() => platform.init();

  /// A button, tab or card was pressed.
  static void tick() => platform.tick();

  /// A picker or wheel moved to the next value.
  static void selection() => platform.selection();

  /// An action completed (photo captured).
  static void confirm() => platform.confirm();
}
