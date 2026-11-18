import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/evacuation_center.dart';

/// A center's capacity as the backend's capacity_source says it
/// (docs/backend/apps-api-2026-11-transfers-capacity.md 3.2):
/// official "48 / 112", estimated "48 / 112 est.", unknown
/// "48 / – (capacity unknown)": never 0 or a blank, never full.
/// [resident] uses the resident wording, "(estimated)".
String capacityFigure(
  AppLocalizations l10n, {
  required int? capacity,
  String? source,
  int? occupancy,
  bool resident = false,
}) {
  final unknown = source == 'unknown' || capacity == null || capacity <= 0;
  if (unknown) {
    return occupancy == null
        ? l10n.capacityUnknownTag
        : l10n.capacityOccupancyUnknown(occupancy);
  }
  final estimated = source == 'estimated';
  if (occupancy == null) {
    if (!estimated) return '$capacity';
    return resident
        ? l10n.capacityResidentEstimated('$capacity')
        : l10n.capacityEstimated('$capacity');
  }
  if (!estimated) return '$occupancy / $capacity';
  return resident
      ? l10n.capacityResidentEstimated('$occupancy / $capacity')
      : l10n.capacityEstimated('$occupancy / $capacity');
}

/// The same for an [EvacuationCenter].
String centerCapacityFigure(
  AppLocalizations l10n,
  EvacuationCenter center, {
  bool withOccupancy = true,
  bool resident = false,
}) => capacityFigure(
  l10n,
  capacity: center.capacityPersons,
  source: center.capacitySource,
  occupancy: withOccupancy ? center.currentOccupancy : null,
  resident: resident,
);

/// The tooltip for an estimate: how it was made.
String? capacityBasisTooltip(AppLocalizations l10n, String? basis) =>
    switch (basis) {
      'peak_2025' => l10n.capacityBasisPeak,
      'type_median' => l10n.capacityBasisMedian,
      _ => null,
    };

/// A percentage only for a known capacity (unknown is never full).
bool showsOccupancyPercent(EvacuationCenter center) =>
    !center.isCapacityUnknown && center.occupancyPercent != null;
