import 'dart:js_interop';

/// Defined in `web/app_status.js`.
@JS('kaloratBadgePermission')
external JSString _permission();

@JS('kaloratRequestBadgePermission')
external JSPromise<JSString> _requestPermission();

@JS('kaloratSetBadge')
external void _setBadge(int count);

@JS('kaloratKeepScreenOn')
external void _keepScreenOn(bool on);

/// Whether the app icon may show a count. Safari shows one only once
/// notifications are allowed.
enum BadgePermission { granted, denied, notAsked, unsupported }

BadgePermission _parse(String value) => switch (value) {
  'granted' => BadgePermission.granted,
  'denied' => BadgePermission.denied,
  'default' => BadgePermission.notAsked,
  _ => BadgePermission.unsupported,
};

BadgePermission badgePermission() {
  try {
    return _parse(_permission().toDart);
  } catch (_) {
    return BadgePermission.unsupported;
  }
}

/// Asks for the permission. Call it from a tap: Safari only asks then.
Future<BadgePermission> requestBadgePermission() async {
  try {
    return _parse((await _requestPermission().toDart).toDart);
  } catch (_) {
    return BadgePermission.unsupported;
  }
}

/// Shows [count] on the app icon; 0 clears it.
void setAppBadge(int count) {
  try {
    _setBadge(count);
  } catch (_) {
    // app_status.js did not load.
  }
}

/// Keeps the screen on while [on], as long as the app is shown.
void keepScreenOn(bool on) {
  try {
    _keepScreenOn(on);
  } catch (_) {
    // No wake lock in this browser.
  }
}
