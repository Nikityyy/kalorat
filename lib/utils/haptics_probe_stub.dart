// The haptics test only exists in the web build (web/haptics_probe.js).

bool hapticProbeAvailable() => false;

void placeHapticProbe(
  int id,
  String mode,
  double left,
  double top,
  double width,
  double height,
) {}

int hapticProbeToggles(int id) => 0;

void removeHapticProbe(int id) {}

bool scriptedHapticProbe() => false;

bool vibrateHapticProbe() => false;

String hapticProbeInfo() => '';
