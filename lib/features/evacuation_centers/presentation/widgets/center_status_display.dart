import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/evacuation_center.dart';

/// Localized display label for an evacuation center's `status` field
/// (`active`/`nearly_full`/`full`/`closed`/`on_standby` —
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
    'nearly_full' => l10n.statusNearlyFull,
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

/// A center status colour, the web's marker colours (backend bd5b433):
/// active green, on standby blue, full red, closed dark gray. Always
/// shown with the status word.
Color centerStatusColorOf(String status) => switch (status.toLowerCase()) {
  'active' => const Color(0xFF15803D),
  'nearly_full' => const Color(0xFFB45309),
  'full' => const Color(0xFFDC2626),
  'closed' => const Color(0xFF374151),
  _ => const Color(0xFF2563EB),
};

/// The colour of a center's status as the API returns it: the effective
/// status (people inside make a center active, or full near capacity),
/// never worked out again from occupancy here.
Color centerStatusColor(BuildContext context, EvacuationCenter center) =>
    centerStatusColorOf(center.status);
