import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

export 'philippine_time.dart' show formatShortDateTime;

/// One way to write numbers, durations and dates everywhere in the app
/// (0.4.0 Part 1): "1,669", "3 days", "Nov 19, 1:44 AM".

/// A whole number with thousands separators ("1,669"); "–" for null.
String formatCount(num? value) =>
    value == null ? '–' : NumberFormat.decimalPattern().format(value);

/// The largest whole unit of [d]: "less than a minute", "5 minutes",
/// "2 hours", "3 days". Rounded down, so "1 day" means one full day.
String formatDuration(AppLocalizations l10n, Duration d) {
  if (d.isNegative) d = Duration.zero;
  if (d.inDays >= 1) return l10n.durationDays(d.inDays);
  if (d.inHours >= 1) return l10n.durationHours(d.inHours);
  if (d.inMinutes >= 1) return l10n.durationMinutes(d.inMinutes);
  return l10n.durationLessThanMinute;
}

/// "3 days ago" from [moment] to [now] (defaults to the phone's clock).
String formatAgo(AppLocalizations l10n, DateTime moment, {DateTime? now}) =>
    l10n.durationAgo(
      formatDuration(l10n, (now ?? DateTime.now()).difference(moment)),
    );

/// Parses a server time (ISO 8601 with offset); null when absent or bad.
DateTime? parseServerTime(Object? raw) =>
    raw is String && raw.isNotEmpty ? DateTime.tryParse(raw) : null;
