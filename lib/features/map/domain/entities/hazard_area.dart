import 'package:latlong2/latlong.dart';

/// A hazard-prone area (flood, landslide, etc.), drawn as a polygon on
/// the hazard map.
///
/// Depends on `latlong2` for [LatLng] rather than staying 100%
/// dependency-free like [EvacuationCenter] — a deliberate, small
/// exception: `latlong2` is a tiny, pure-Dart geographic-coordinate
/// package (no Flutter dependency of its own), and every layer that
/// touches this entity (the map rendering widgets especially) needs
/// `LatLng` anyway. Converting to and from a custom coordinate type at
/// each layer boundary would add real boilerplate for no practical
/// benefit.
class HazardArea {
  const HazardArea({
    required this.id,
    required this.name,
    required this.hazardType,
    required this.boundary,
    this.severityLevel,
    this.description,
  });

  final int id;
  final String name;

  /// e.g. "flood", "landslide" — kept as a plain String rather than a
  /// Dart enum, since the exact vocabulary the backend uses for this
  /// field hasn't been confirmed against a real response yet.
  final String hazardType;

  /// Not sent by the backend today (see [HazardAreaModel.fromGeoJsonFeature]);
  /// stays null rather than a guessed value.
  final String? severityLevel;

  /// Free-text description of the hazard area, e.g. "Flood-prone
  /// riverside barangay."
  final String? description;

  /// The polygon's exterior boundary. GeoJSON Polygon geometry can
  /// include interior rings (holes) too, but those aren't parsed here
  /// — not expected to matter for hazard-zone shapes, and easy to add
  /// later if a real response ever needs it.
  final List<LatLng> boundary;
}
