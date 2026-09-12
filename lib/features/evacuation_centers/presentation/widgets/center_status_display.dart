import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/evacuation_center.dart';

/// Localized display label for an evacuation center's `status` field
/// (`active`/`full`/`closed`/`on_standby`, from the migrations —
/// verified against the Laravel source, not guessed). Backend enum
/// values are never changed by this — only how they're displayed.
///
/// An unrecognized status (shouldn't happen given the confirmed enum,
/// but backend vocabulary could grow) falls back to showing the raw
/// value exactly as sent, the same "don't invent, don't hide" policy
/// [alertTypeLabel] uses for free-form `alert_type` text.
String localizedCenterStatus(BuildContext context, String status) {
  final l10n = AppLocalizations.of(context);
  return switch (status.toLowerCase()) {
    'active' => l10n.statusActive,
    'full' => l10n.statusFull,
    'closed' => l10n.statusClosed,
    'on_standby' => l10n.statusOnStandby,
    _ => status,
  };
}

/// Localized display label for an evacuation center's `type` field —
/// verified against `StoreEvacuationCenterRequest`'s exact enum
/// (`school`, `covered_court`, `church`, `barangay_hall`, `gymnasium`,
/// `other`) on `elikas-backend-main (4)`. Same "don't invent, don't
/// hide" fallback as [localizedCenterStatus] for an unrecognized value.
String localizedCenterType(BuildContext context, String type) {
  final l10n = AppLocalizations.of(context);
  return switch (type.toLowerCase()) {
    'school' => l10n.centerTypeSchool,
    'covered_court' => l10n.centerTypeCoveredCourt,
    'church' => l10n.centerTypeChurch,
    'barangay_hall' => l10n.centerTypeBarangayHall,
    'gymnasium' => l10n.centerTypeGymnasium,
    'other' => l10n.centerTypeOther,
    _ => type,
  };
}

/// The exact backend enum values `StoreEvacuationCenterRequest`
/// accepts for `type`, in a sensible fixed display order — reused by
/// the Add/Edit Center form's dropdown so the payload always sends one
/// of these, never an invented value.
const evacuationCenterTypeValues = [
  'school',
  'covered_court',
  'church',
  'barangay_hall',
  'gymnasium',
  'other',
];

/// The one colour every screen showing a center's status/occupancy
/// uses — lifted out of what was a private `EvacuationCenterCard`
/// method so Nearest Center and Evacuation Center Details can match it
/// exactly instead of each growing a slightly different copy.
///
/// Same colour bands as the web admin dashboard's evacuation center
/// cards: under 75% reads as healthy capacity, 75–94% as filling up,
/// 95%+ as effectively full. A closed center's occupancy number isn't a
/// meaningful signal at all, so it gets the neutral colour regardless
/// of whatever number the backend reports for it — same treatment as a
/// center with no occupancy data at all (e.g. from the `/nearest`
/// endpoint).
Color centerStatusColor(BuildContext context, EvacuationCenter center) {
  final theme = Theme.of(context);
  final semantic = theme.extension<AppSemanticColors>()!;
  final status = center.status.toLowerCase();
  final occupancyPercent = center.occupancyPercent;

  if (status.contains('closed') || occupancyPercent == null) {
    return theme.colorScheme.onSurfaceVariant;
  }
  // 'full' reads as red even on the rare chance occupancy_percent
  // itself hasn't caught up to 95+ yet — the status field is the more
  // authoritative signal when the two disagree.
  if (status == 'full' || occupancyPercent >= 95) {
    return theme.colorScheme.error;
  }
  if (occupancyPercent >= 75) return semantic.warning;
  return semantic.success;
}
