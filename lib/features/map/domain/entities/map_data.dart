import '../../../evacuation_centers/domain/entities/evacuation_center.dart';
import 'hazard_area.dart';

/// Everything the hazard map screen needs: centers and hazard areas
/// together, as returned by `/public/gis/map-data`.
///
/// Reuses [EvacuationCenter] from the evacuation_centers feature's
/// domain layer rather than defining a parallel type — cross-feature
/// reuse of a *domain* entity is the deliberate pattern here (reaching
/// into another feature's data or presentation layer would not be).
class MapData {
  const MapData({required this.centers, required this.hazardAreas});

  final List<EvacuationCenter> centers;
  final List<HazardArea> hazardAreas;
}
