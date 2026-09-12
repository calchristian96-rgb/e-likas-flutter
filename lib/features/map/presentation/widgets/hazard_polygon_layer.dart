import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/hazard_area.dart';

/// Builds the [Polygon] list for a [PolygonLayer] from [hazardAreas].
///
/// Kept as its own small function rather than inline in the page
/// widget, matching the folder structure agreed in the architecture
/// plan (`hazard_polygon_layer.dart`).
List<Polygon> buildHazardPolygons(List<HazardArea> hazardAreas) {
  return [
    for (final hazard in hazardAreas)
      Polygon(
        points: hazard.boundary,
        color: hazardTypeColor(hazard.hazardType).withValues(alpha: 0.35),
        borderColor: hazardTypeColor(hazard.hazardType),
        borderStrokeWidth: 2,
        label: hazard.name,
      ),
  ];
}

/// Colors keyed by the real `hazard_type` enum — confirmed directly
/// against the Laravel migration
/// (`2026_01_01_000010_create_hazard_prone_areas_table.php`, read-only):
/// `enum('hazard_type', ['flood', 'landslide', 'lahar', 'storm_surge',
/// 'volcanic_danger_zone'])`. Previously guessed at 'fire'/'earthquake',
/// neither of which exist in the real enum, while missing 'lahar' and
/// 'volcanic_danger_zone' (both genuinely relevant near Mayon Volcano)
/// entirely. Falls back to a neutral color for anything unrecognized
/// rather than failing, in case the backend enum ever grows.
Color hazardTypeColor(String hazardType) {
  switch (hazardType.toLowerCase()) {
    case 'flood':
      return Colors.blue;
    case 'landslide':
      return Colors.brown;
    case 'lahar':
      return Colors.deepOrange;
    case 'storm_surge':
      return Colors.indigo;
    case 'volcanic_danger_zone':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

/// Human-readable label for a real `hazard_type` value — turns
/// `volcanic_danger_zone` into "Volcanic danger zone". The raw value
/// itself is never altered anywhere; this only decides how the layers
/// sheet/legend/filter chips display it, same pattern as
/// [localizedCenterStatus]/[alertSeverityLabel] elsewhere in this app.
/// An unrecognized type (the enum could grow) falls back to a plain
/// cleaned-up version of the raw string rather than hiding it.
String hazardTypeLabel(BuildContext context, String hazardType) {
  final l10n = AppLocalizations.of(context);
  return switch (hazardType.toLowerCase()) {
    'flood' => l10n.hazardTypeFlood,
    'landslide' => l10n.hazardTypeLandslide,
    'lahar' => l10n.hazardTypeLahar,
    'storm_surge' => l10n.hazardTypeStormSurge,
    'volcanic_danger_zone' => l10n.hazardTypeVolcanicDangerZone,
    _ => _titleCase(hazardType),
  };
}

String _titleCase(String value) {
  final cleaned = value.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  if (cleaned.isEmpty) return value;
  return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
}
