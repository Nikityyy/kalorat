/// Portrait width / height of a camera preview that reports [reported] as its
/// aspect ratio. Phones report landscape or portrait depending on timing, and
/// Safari can report 0x0 (NaN / infinity here) right after the camera
/// (re)starts, so anything unusable falls back to 9:16.
double portraitPreviewAspect(double reported) {
  if (!reported.isFinite || reported <= 0) return 9 / 16;
  return reported > 1 ? 1 / reported : reported;
}
