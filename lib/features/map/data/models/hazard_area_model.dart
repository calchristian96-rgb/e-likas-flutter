import 'package:latlong2/latlong.dart';

import '../../domain/entities/hazard_area.dart';

/// Drift cache row *and* GeoJSON `Polygon` Feature model for hazard
/// areas, from `/public/gis/map-data`.
///
/// The backend's own `id` is used directly as the Drift primary key —
/// `insertAllOnConflictUpdate` upserts naturally since it's the real,
/// stable backend id. The polygon boundary is stored as a flat
/// `List<double>` (`[lat1, lng1, lat2, lng2, ...]`), joined as a CSV
/// string in the Drift row (`HazardAreas.boundaryLatLngFlatCsv`) since
/// Drift has no native list-of-double column type.
class HazardAreaModel {
  HazardAreaModel({
    required this.id,
    required this.name,
    required this.hazardType,
    required this.boundaryLatLngFlat,
    this.severityLevel,
    this.description,
  });

  final int id;
  final String name;
  final String hazardType;
  final String? severityLevel;

  /// Free-text description of the hazard area, from `properties.description`.
  final String? description;

  /// Polygon exterior-ring boundary, flattened as
  /// `[lat1, lng1, lat2, lng2, ...]`. See [HazardArea.boundary] and
  /// [toLatLngList] for the reconstructed form.
  final List<double> boundaryLatLngFlat;

  /// Parses a GeoJSON `Polygon` Feature. Only the exterior ring
  /// (`coordinates[0]`) is kept — interior rings (holes) aren't
  /// expected to matter for hazard-zone shapes and aren't parsed.
  ///
  /// Property names verified against
  /// `App\Http\Controllers\Api\GisController::mapData()`: the
  /// displayed name comes from `area_name` (there is no `name` key),
  /// and `description` is available but `severity_level` is not
  /// something the backend sends at all — it stays null rather than
  /// being guessed at.
  factory HazardAreaModel.fromGeoJsonFeature(
    Map<String, dynamic> properties,
    Map<String, dynamic> geometry,
  ) {
    final rings = geometry['coordinates'] as List;
    final exteriorRing = (rings.first as List).cast<List<dynamic>>();

    final flat = <double>[];
    for (final point in exteriorRing) {
      final coords = point.cast<num>();
      flat.add(coords[1].toDouble()); // lat
      flat.add(coords[0].toDouble()); // lng — GeoJSON order is [lng, lat]
    }

    return HazardAreaModel(
      id: properties['id'] as int,
      name: (properties['area_name'] as String?) ?? 'Hazard area',
      hazardType: (properties['hazard_type'] as String?) ?? 'unknown',
      severityLevel: properties['severity_level'] as String?,
      description: properties['description'] as String?,
      boundaryLatLngFlat: flat,
    );
  }

  List<LatLng> toLatLngList() {
    final points = <LatLng>[];
    for (var i = 0; i + 1 < boundaryLatLngFlat.length; i += 2) {
      points.add(LatLng(boundaryLatLngFlat[i], boundaryLatLngFlat[i + 1]));
    }
    return points;
  }

  HazardArea toEntity() {
    return HazardArea(
      id: id,
      name: name,
      hazardType: hazardType,
      severityLevel: severityLevel,
      description: description,
      boundary: toLatLngList(),
    );
  }
}
