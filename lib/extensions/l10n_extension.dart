import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';

/// Convenience extension to access AppLocalizations from BuildContext.
///
/// Usage:
/// ```dart
/// Text(context.l10n.settings)
/// ```
extension LocalizationExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
