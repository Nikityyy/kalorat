import 'haptics_stub.dart'
    if (dart.library.js_interop) 'haptics_web.dart'
    as platform;

/// Short physical feedback for taps. Call it from the tap handler itself: the
/// web build (Android browsers) only vibrates during a user gesture; iOS
/// browsers have no haptics for web pages.
class Haptics {
  const Haptics._();

  /// A button, tab or card was pressed.
  static void tick() => platform.tick();

  /// A picker or wheel moved to the next value.
  static void selection() => platform.selection();

  /// An action completed (photo captured).
  static void confirm() => platform.confirm();
}
