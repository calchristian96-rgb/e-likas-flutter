import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../utils/data_freshness_formatter.dart';

/// A slim, calm banner shown when the device has no connectivity — an
/// amber "offline mode" notice rather than an alarming red error, since
/// this is expected, handled behavior in an offline-first app, not a
/// failure. Returns an empty [SizedBox] when [isOffline] is false, so
/// it can be placed unconditionally at the top of a screen's body.
///
/// When [lastUpdated] is known, the message names how old the cached
/// data actually is instead of just "showing saved information" — and
/// once that's 24h+ old, switches to a warning icon plus explicit
/// "Caution" wording rather than only a colour change, so stale
/// emergency information doesn't rely on colour alone to register.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.isOffline, this.lastUpdated});

  final bool isOffline;

  /// The moment the currently-shown data was last confirmed on this
  /// device — the same signal the Home footer's [LastUpdatedLabel]
  /// already tracks, not a newly-invented timestamp.
  final DateTime? lastUpdated;

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final stale = isDataStale(lastUpdated);
    final accent = stale ? theme.colorScheme.error : semantic.warning;

    final message = switch (lastUpdated) {
      null => '${l10n.offlineModeLabel} — ${l10n.showingSavedInfo}',
      final since when stale =>
        '${l10n.freshnessCaution} — ${l10n.freshnessLastUpdatedVerb} '
            '${formatElapsedSince(since)}.',
      final since =>
        '${l10n.offline} • '
            '${since.difference(DateTime.now()).inMinutes.abs() < 5 ? l10n.freshnessSavedVerb : l10n.freshnessLastUpdatedVerb} '
            '${formatElapsedSince(since)}',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      color: accent.withValues(alpha: 0.14),
      child: Row(
        children: [
          Icon(
            stale ? Icons.warning_amber_rounded : Icons.cloud_off_outlined,
            size: 16,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
