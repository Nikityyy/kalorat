import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// "Today, 12:41", "Yesterday, 08:12" or "Oct 20, 2026, 19:05".
String mealTimeLabel(
  AppLocalizations l10n,
  String language,
  DateTime t, {
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(t.year, t.month, t.day);
  final clock = DateFormat.Hm(language).format(t);
  if (day == today) return l10n.todayAt(clock);
  // Not today minus 24 hours: on the day the clocks change that is 23:00.
  if (day == DateTime(n.year, n.month, n.day - 1)) {
    return l10n.yesterdayAt(clock);
  }
  return '${DateFormat.yMMMd(language).format(t)}, $clock';
}
