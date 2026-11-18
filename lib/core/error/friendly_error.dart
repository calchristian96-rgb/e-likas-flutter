import '../../l10n/app_localizations.dart';
import 'failure.dart';

/// What a resident reads when a screen cannot load: [base] in their own
/// words, never the technical error. With no connection and nothing
/// saved yet, it also says how to get a saved copy.
String friendlyLoadError(AppLocalizations l10n, String base, Object? error) {
  if (error is NetworkFailure || error is CacheFailure) {
    return '$base. ${l10n.noSavedCopyYet}';
  }
  return base;
}
