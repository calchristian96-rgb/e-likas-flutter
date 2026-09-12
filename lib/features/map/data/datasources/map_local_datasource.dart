import 'package:drift/drift.dart';

import '../../../../core/database/resident_database.dart';
import '../../../evacuation_centers/data/datasources/evacuation_centers_local_datasource.dart';
import '../../../evacuation_centers/data/models/evacuation_center_model.dart';
import '../models/hazard_area_model.dart';

typedef CachedMapFeatures = ({
  List<EvacuationCenterModel> centers,
  List<HazardAreaModel> hazardAreas,
});

/// Drift-backed cache for the GIS map's two feature layers.
///
/// Centers are read/written through the exact same `evacuation_centers`
/// Drift table `EvacuationCentersLocalDatasource` uses — same backend
/// records reached through a different endpoint, sharing one cache
/// rather than two. Hazard areas are this datasource's own table.
class MapLocalDatasource {
  const MapLocalDatasource(this._db);

  final ResidentDatabase _db;

  Future<CachedMapFeatures> getCachedMapData() async {
    final centersDatasource = EvacuationCentersLocalDatasource(_db);
    final centers = await centersDatasource.getCachedCenters();
    final hazardRows = await _db.select(_db.hazardAreas).get();
    return (centers: centers, hazardAreas: hazardRows.map(_fromRow).toList());
  }

  /// See `EvacuationCentersLocalDatasource.cacheCenters`'s doc comment
  /// for why centers are merged rather than blindly upserted —
  /// `GisController::mapData()` always includes a real `photo_url` key,
  /// so `photoUrlIsAuthoritative: true` here matches that datasource's
  /// own reasoning for the GIS caller specifically.
  Future<void> cacheMapData(
    List<EvacuationCenterModel> centers,
    List<HazardAreaModel> hazardAreas,
  ) async {
    final centersDatasource = EvacuationCentersLocalDatasource(_db);
    await centersDatasource.cacheCenters(
      centers,
      photoUrlIsAuthoritative: true,
    );
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.hazardAreas, [
        for (final area in hazardAreas) _toHazardCompanion(area),
      ]);
    });
  }

  static HazardAreasCompanion _toHazardCompanion(HazardAreaModel m) {
    return HazardAreasCompanion.insert(
      id: Value(m.id),
      name: m.name,
      hazardType: m.hazardType,
      severityLevel: Value(m.severityLevel),
      description: Value(m.description),
      boundaryLatLngFlatCsv: m.boundaryLatLngFlat.join(','),
    );
  }

  static HazardAreaModel _fromRow(HazardAreaRow row) {
    final flat = row.boundaryLatLngFlatCsv.isEmpty
        ? <double>[]
        : row.boundaryLatLngFlatCsv.split(',').map(double.parse).toList();
    return HazardAreaModel(
      id: row.id,
      name: row.name,
      hazardType: row.hazardType,
      boundaryLatLngFlat: flat,
      severityLevel: row.severityLevel,
      description: row.description,
    );
  }
}
