import '../l10n/app_localizations.dart';
import '../services/gemini_service.dart';

/// What to tell the user when an analysis fails. The technical details stay in
/// the log; the user only needs to know what happened and what to do.
String analysisErrorMessage(AppLocalizations l10n, Object error) {
  return switch (error is GeminiError ? error.type : null) {
    GeminiErrorType.timedOut => l10n.analysisTimedOut,
    GeminiErrorType.networkError => l10n.analysisNoConnection,
    GeminiErrorType.rateLimited => l10n.analysisRateLimited,
    GeminiErrorType.invalidApiKey => l10n.invalidApiKeyError,
    _ => l10n.analysisFailed,
  };
}
