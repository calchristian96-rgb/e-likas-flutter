import 'package:drift/drift.dart';

import '../../../../core/database/staff_database.dart';
import '../../../../core/utils/fast_hash.dart';
import '../models/cached_family_model.dart';

/// Drift-backed cache over the registered-families cache, in the
/// encrypted staff [StaffDatabase] — same split of responsibility as
/// every other feature's local datasource (no JSON parsing or
/// domain-entity mapping here, that's `RegisteredFamiliesRepositoryImpl`'s
/// job).
///
/// Reads/writes are scoped by a real SQL `WHERE ownerStaffId = ?`
/// (the Drift table's composite primary key is `(familyId,
/// ownerStaffId)` — see `CachedFamilies`'s own doc comment) rather
/// than fetch-everything-then-filter-in-Dart — a real query-level
/// ownership boundary, not just an in-memory filter: one staff account
/// must never even transiently hold another's cached rows in memory.
class RegisteredFamiliesLocalDataSource {
  const RegisteredFamiliesLocalDataSource(this._db);

  final StaffDatabase _db;

  Future<List<CachedFamilyModel>> getAllForOwner(int ownerStaffId) async {
    final rows = await (_db.select(
      _db.cachedFamilies,
    )..where((t) => t.ownerStaffId.equals(ownerStaffId))).get();
    return rows.map(_fromRow).toList();
  }

  /// Clears every row this [ownerStaffId] previously cached, then
  /// writes [models] — a full replace, not an accumulative merge: a
  /// stale family that's since been synced elsewhere/edited/removed on
  /// the backend should disappear from this cache on the next
  /// successful fetch, not linger forever.
  Future<void> replaceAllForOwner(
    int ownerStaffId,
    List<CachedFamilyModel> models,
  ) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.cachedFamilies,
      )..where((t) => t.ownerStaffId.equals(ownerStaffId))).go();
      await _db.batch((batch) {
        batch.insertAll(_db.cachedFamilies, [
          for (final model in models) _toCompanion(model),
        ]);
      });
    });
  }

  static CachedFamiliesCompanion _toCompanion(CachedFamilyModel m) {
    return CachedFamiliesCompanion.insert(
      familyId: m.familyId,
      ownerStaffId: m.ownerStaffId,
      barangayId: Value(m.barangayId),
      barangayName: m.barangayName,
      headOfFamilyName: m.headOfFamilyName,
      homeAddress: Value(m.homeAddress),
      memberCount: m.memberCount,
      evacuationCenterName: Value(m.evacuationCenterName),
      is4psBeneficiary: Value(m.is4psBeneficiary),
      createdAtEpochMs: Value(m.createdAtEpochMs),
      memberNamesNewlineJoined: Value(m.memberNames.join('\n')),
    );
  }

  static CachedFamilyModel _fromRow(CachedFamilyRow row) {
    return CachedFamilyModel(
      id: cachedFamilyId(
        ownerStaffId: row.ownerStaffId,
        familyId: row.familyId,
      ),
      familyId: row.familyId,
      ownerStaffId: row.ownerStaffId,
      barangayId: row.barangayId,
      barangayName: row.barangayName,
      headOfFamilyName: row.headOfFamilyName,
      homeAddress: row.homeAddress,
      memberCount: row.memberCount,
      evacuationCenterName: row.evacuationCenterName,
      is4psBeneficiary: row.is4psBeneficiary,
      createdAtEpochMs: row.createdAtEpochMs,
      memberNames: row.memberNamesNewlineJoined.isEmpty
          ? const []
          : row.memberNamesNewlineJoined.split('\n'),
    );
  }
}

/// Same derived-id scheme as [CachedFamilyModel.id]'s doc comment —
/// still needed so [CachedFamilyModel] (the in-memory shape every
/// repository/provider above this layer works with) always has a real
/// `id`, even though the Drift table itself no longer needs one (it
/// keys on the real `(familyId, ownerStaffId)` pair directly).
int cachedFamilyId({required int ownerStaffId, required int familyId}) =>
    fastHash('$ownerStaffId:$familyId');
