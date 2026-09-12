/// Icon, colour and label for an alert's `alertType`.
///
/// Lifted out of [AlertListTile] (where the icon mapping originally
/// lived, unchanged in behaviour) so the details screen shows the same
/// icon for the same alert as the row the resident tapped to get there.
/// Two independent copies of this mapping would be free to drift, and
/// an alert that changes appearance between the list and its own
/// details page reads as a different alert.
///
/// Matching is substring-based on a lowercased string rather than an
/// exhaustive switch over known values, because `alert_type` is
/// free-form text from the backend and its full vocabulary isn't
/// confirmed. Anything unrecognised falls through to a neutral
/// "information" presentation rather than throwing.
library;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

IconData alertTypeIcon(String alertType) {
  final normalized = alertType.toLowerCase();
  if (normalized.contains('evacuat')) return Icons.directions_run;
  if (normalized.contains('critical') || normalized.contains('emergency')) {
    return Icons.warning_amber_rounded;
  }
  if (normalized.contains('warning')) return Icons.error_outline;
  if (normalized.contains('all_clear') || normalized.contains('clear')) {
    return Icons.check_circle_outline;
  }
  return Icons.info_outline;
}

/// Severity colour for [alertType], following the same branch order as
/// [alertTypeIcon] so the two never disagree about which category an
/// alert falls into.
///
/// Uses the existing [AppSemanticColors] theme extension for the
/// warning/success roles rather than hardcoded [Colors] constants — the
/// same reasoning that extension was created for, so dark mode keeps
/// working.
Color alertTypeColor(BuildContext context, String alertType) {
  final theme = Theme.of(context);
  final semantic = theme.extension<AppSemanticColors>();
  final normalized = alertType.toLowerCase();

  if (normalized.contains('evacuat') ||
      normalized.contains('critical') ||
      normalized.contains('emergency')) {
    return theme.colorScheme.error;
  }
  if (normalized.contains('warning')) {
    return semantic?.warning ?? theme.colorScheme.error;
  }
  if (normalized.contains('all_clear') || normalized.contains('clear')) {
    return semantic?.success ?? theme.colorScheme.primary;
  }
  return theme.colorScheme.primary;
}

/// A human-readable version of the raw `alert_type` value — turns
/// `all_clear` into `All clear`. Purely cosmetic; the raw value is
/// still what every branch above matches on.
String alertTypeLabel(String alertType) {
  final cleaned = alertType.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  if (cleaned.isEmpty) return 'Advisory';
  return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
}

/// Icon/color/label for an alert's `severity` field
/// (`mandatory`/`advisory`/`info`/`all_clear`, per `AlertResource`) —
/// the actual urgency signal the backend sends, distinct from
/// `alert_type` (which just names the hazard: typhoon/flood/etc.).
/// Exact mapping as specified: mandatory reads as a real emergency
/// (theme error red), advisory as warning orange, info as primary
/// blue, all_clear as success green. An unrecognized or missing value
/// never invents a new severity — it falls back to the neutral
/// info/advisory treatment.
IconData alertSeverityIcon(String? severity) {
  return switch (severity) {
    'mandatory' => Icons.warning_amber_rounded,
    'advisory' => Icons.error_outline,
    'info' => Icons.info_outline,
    'all_clear' => Icons.check_circle_outline,
    _ => Icons.info_outline,
  };
}

Color alertSeverityColor(BuildContext context, String? severity) {
  final theme = Theme.of(context);
  final semantic = theme.extension<AppSemanticColors>();
  return switch (severity) {
    'mandatory' => theme.colorScheme.error,
    'advisory' => semantic?.warning ?? theme.colorScheme.error,
    'info' => theme.colorScheme.primary,
    'all_clear' => semantic?.success ?? theme.colorScheme.primary,
    _ => theme.colorScheme.primary,
  };
}

String alertSeverityLabel(BuildContext context, String? severity) {
  final l10n = AppLocalizations.of(context);
  return switch (severity) {
    'mandatory' => l10n.severityMandatory,
    'advisory' => l10n.severityAdvisory,
    'info' => l10n.severityInfo,
    'all_clear' => l10n.severityAllClear,
    _ => l10n.severityAdvisory,
  };
}

/// True for the one severity that should read as a real emergency —
/// used by callers that give critical alerts extra visual emphasis
/// (e.g. a thicker card border).
bool isMandatorySeverity(String? severity) => severity == 'mandatory';

/// Prefers the real `severity` field when the backend sent one;
/// falls back to the `alert_type`-based heuristic only when it
/// didn't, so an older cached alert without a `severity` value still
/// gets a sensible presentation instead of a blank one.
IconData alertDisplayIcon(String alertType, String? severity) {
  return severity != null
      ? alertSeverityIcon(severity)
      : alertTypeIcon(alertType);
}

Color alertDisplayColor(
  BuildContext context,
  String alertType,
  String? severity,
) {
  return severity != null
      ? alertSeverityColor(context, severity)
      : alertTypeColor(context, alertType);
}

String alertDisplayLabel(
  BuildContext context,
  String alertType,
  String? severity,
) {
  return severity != null
      ? alertSeverityLabel(context, severity)
      : alertTypeLabel(alertType);
}
