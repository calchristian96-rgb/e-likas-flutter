import 'package:drift/drift.dart';

import '../../../../core/database/staff_database.dart';
import '../models/lookup_barangay_model.dart';
import '../models/lookup_evacuation_center_model.dart';
import '../models/lookup_evacuation_event_model.dart';

/// Drift-backed cache for the three lookup lists, in the encrypted
/// staff [StaffDatabase] — never the resident [ResidentDatabase].
///
/// Each cache is replaced wholesale on refresh (clear, then insert)
/// rather than accumulated: these are small, complete reference lists,
/// so a stale row from a renamed/removed record staying around forever
/// would be a bug, not a feature.
class LookupLocalDataSource {
  const LookupLocalDataSource(this._db);

  final StaffDatabase _db;

  Future<List<LookupBarangayModel>> getCachedBarangays() async {
    final rows = await _db.select(_db.lookupBarangays).get();
    return [
      for (final row in rows) LookupBarangayModel(id: row.id, name: row.name),
    ];
  }

  Future<void> cacheBarangays(List<LookupBarangayModel> items) async {
    await _db.transaction(() async {
      await _db.delete(_db.lookupBarangays).go();
      await _db.batch((batch) {
        batch.insertAll(_db.lookupBarangays, [
          for (final item in items)
            LookupBarangaysCompanion.insert(
              id: Value(item.id),
              name: item.name,
            ),
        ]);
      });
    });
  }

  Future<List<LookupEvacuationEventModel>> getCachedEvacuationEvents() async {
    final rows = await _db.select(_db.lookupEvacuationEvents).get();
    return [
      for (final row in rows)
        LookupEvacuationEventModel(
          id: row.id,
          name: row.name,
          status: row.status,
          startDate: row.startDate,
          endDate: row.endDate,
        ),
    ];
  }

  Future<void> cacheEvacuationEvents(
    List<LookupEvacuationEventModel> items,
  ) async {
    await _db.transaction(() async {
      await _db.delete(_db.lookupEvacuationEvents).go();
      await _db.batch((batch) {
        batch.insertAll(_db.lookupEvacuationEvents, [
          for (final item in items)
            LookupEvacuationEventsCompanion.insert(
              id: Value(item.id),
              name: item.name,
              status: item.status,
              startDate: Value(item.startDate),
              endDate: Value(item.endDate),
            ),
        ]);
      });
    });
  }

  Future<List<LookupEvacuationCenterModel>> getCachedEvacuationCenters() async {
    final rows = await _db.select(_db.lookupEvacuationCenters).get();
    return [
      for (final row in rows)
        LookupEvacuationCenterModel(
          id: row.id,
          name: row.name,
          barangayId: row.barangayId,
          status: row.status,
        ),
    ];
  }

  Future<void> cacheEvacuationCenters(
    List<LookupEvacuationCenterModel> items,
  ) async {
    await _db.transaction(() async {
      await _db.delete(_db.lookupEvacuationCenters).go();
      await _db.batch((batch) {
        batch.insertAll(_db.lookupEvacuationCenters, [
          for (final item in items)
            LookupEvacuationCentersCompanion.insert(
              id: Value(item.id),
              name: item.name,
              barangayId: item.barangayId,
              status: item.status,
            ),
        ]);
      });
    });
  }
}
