import 'package:drift/drift.dart';

import '../../../../core/database/resident_database.dart';
import '../models/evacuation_center_model.dart';

/// Drift-backed cache for evacuation centers. [EvacuationCenterModel]
/// itself is the in-memory shape every repository/provider above this
/// layer works with.
class EvacuationCentersLocalDatasource {
  const EvacuationCentersLocalDatasource(this._db);

  final ResidentDatabase _db;

  Future<List<EvacuationCenterModel>> getCachedCenters() async {
    final rows = await _db.select(_db.evacuationCenters).get();
    return rows.map(_fromRow).toList();
  }

  /// Writes [centers]. See `EvacuationCenterModel.mergeOverExisting`'s
  /// own doc comment for why a blind upsert here would silently erase
  /// fields a richer fetch already cached (the real device bug this
  /// merge fixed).
  Future<void> cacheCenters(
    List<EvacuationCenterModel> centers, {
    bool photoUrlIsAuthoritative = false,
  }) async {
    await _db.transaction(() async {
      for (final center in centers) {
        final existingRow = await (_db.select(
          _db.evacuationCenters,
        )..where((t) => t.id.equals(center.id))).getSingleOrNull();
        final existing = existingRow == null ? null : _fromRow(existingRow);
        final merged = center.mergeOverExisting(
          existing,
          photoUrlIsAuthoritative: photoUrlIsAuthoritative,
        );
        await _db
            .into(_db.evacuationCenters)
            .insertOnConflictUpdate(_toCompanion(merged));
      }
    });
  }

  static EvacuationCentersCompanion _toCompanion(EvacuationCenterModel m) {
    return EvacuationCentersCompanion.insert(
      id: Value(m.id),
      name: m.name,
      type: m.type,
      address: Value(m.address),
      barangay: Value(m.barangay),
      barangayId: Value(m.barangayId),
      latitude: Value(m.latitude),
      longitude: Value(m.longitude),
      capacityPersons: m.capacityPersons,
      capacityFamilies: Value(m.capacityFamilies),
      currentOccupancy: Value(m.currentOccupancy),
      occupancyPercent: Value(m.occupancyPercent),
      status: m.status,
      distanceMeters: Value(m.distanceMeters),
      photoUrl: Value(m.photoUrl),
      createdBy: Value(m.createdBy),
      campManagerName: Value(m.campManagerName),
      campManagerContact: Value(m.campManagerContact),
    );
  }

  static EvacuationCenterModel _fromRow(EvacuationCenterRow row) {
    return EvacuationCenterModel(
      id: row.id,
      name: row.name,
      type: row.type,
      address: row.address,
      barangay: row.barangay,
      barangayId: row.barangayId,
      latitude: row.latitude,
      longitude: row.longitude,
      capacityPersons: row.capacityPersons,
      capacityFamilies: row.capacityFamilies,
      currentOccupancy: row.currentOccupancy,
      occupancyPercent: row.occupancyPercent,
      status: row.status,
      distanceMeters: row.distanceMeters,
      photoUrl: row.photoUrl,
      createdBy: row.createdBy,
      campManagerName: row.campManagerName,
      campManagerContact: row.campManagerContact,
    );
  }
}
