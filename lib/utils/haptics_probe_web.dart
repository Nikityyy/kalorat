import 'dart:js_interop';

/// Defined in `web/haptics_probe.js`.
@JS('kaloratHapticProbe')
external _ProbeApi? get _api;

extension type _ProbeApi(JSObject _) implements JSObject {
  external void place(
    int id,
    String mode,
    double left,
    double top,
    double width,
    double height,
  );
  external int toggles(int id);
  external void remove(int id);
  external bool scripted();
  external JSAny? vibrate();
  external String info();
}

bool hapticProbeAvailable() => _api != null;

void placeHapticProbe(
  int id,
  String mode,
  double left,
  double top,
  double width,
  double height,
) => _api?.place(id, mode, left, top, width, height);

int hapticProbeToggles(int id) => _api?.toggles(id) ?? 0;

void removeHapticProbe(int id) => _api?.remove(id);

bool scriptedHapticProbe() => _api?.scripted() ?? false;

bool vibrateHapticProbe() => _api?.vibrate().dartify() == true;

String hapticProbeInfo() => _api?.info() ?? '';
