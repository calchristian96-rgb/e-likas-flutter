import 'package:drift/drift.dart';

import '../../../../core/database/staff_database.dart';
import '../../../../core/debug/pending_count_debug_log.dart';
import '../models/pending_family_registration_model.dart';

/// Drift-backed CRUD over the pending-registration queue, in the
/// encrypted staff [StaffDatabase]. No JSON parsing or domain-entity
/// mapping here — that's `PendingQueueRepositoryImpl`'s job, same
/// split as every other feature's local datasource.
class PendingQueueLocalDataSource {
  const PendingQueueLocalDataSource(this._db);

  final StaffDatabase _db;

  Future<List<PendingFamilyRegistrationModel>> getAll() async {
    pendingCountDebugLog('F Drift query starting (getAll)');
    try {
      final rows = await _db.select(_db.pendingFamilyRegistrations).get();
      pendingCountDebugLog('G Drift query completed count=${rows.length}');
      return rows.map(_fromRow).toList();
    } catch (error, stackTrace) {
      pendingCountDebugLog('DATABASE ERROR TYPE=${error.runtimeType}');
      pendingCountDebugLog('DATABASE ERROR=$error (getAll query)');
      pendingCountDebugLog('DATABASE STACK=$stackTrace');
      rethrow;
    }
  }

  Future<PendingFamilyRegistrationModel?> getByLocalId(String localId) async {
    final row = await (_db.select(
      _db.pendingFamilyRegistrations,
    )..where((t) => t.localId.equals(localId))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<void> put(PendingFamilyRegistrationModel model) async {
    await _db
        .into(_db.pendingFamilyRegistrations)
        .insertOnConflictUpdate(_toCompanion(model));
  }

  Future<void> delete(String localId) async {
    await (_db.delete(
      _db.pendingFamilyRegistrations,
    )..where((t) => t.localId.equals(localId))).go();
  }

  static PendingFamilyRegistrationsCompanion _toCompanion(
    PendingFamilyRegistrationModel m,
  ) {
    return PendingFamilyRegistrationsCompanion.insert(
      localId: m.localId,
      createdAtEpochMs: m.createdAtEpochMs,
      updatedAtEpochMs: m.updatedAtEpochMs,
      syncStatus: m.syncStatus,
      attemptCount: Value(m.attemptCount),
      lastAttemptAtEpochMs: Value(m.lastAttemptAtEpochMs),
      lastErrorCategory: Value(m.lastErrorCategory),
      lastErrorMessage: Value(m.lastErrorMessage),
      fieldErrorsJson: Value(m.fieldErrorsJson),
      payloadJson: m.payloadJson,
      headOfFamilyName: m.headOfFamilyName,
      memberCount: m.memberCount,
      barangayName: m.barangayName,
      ownerStaffId: Value(m.ownerStaffId),
    );
  }

  static PendingFamilyRegistrationModel _fromRow(
    PendingFamilyRegistrationRow row,
  ) {
    return PendingFamilyRegistrationModel(
      id: fastHash(row.localId),
      localId: row.localId,
      createdAtEpochMs: row.createdAtEpochMs,
      updatedAtEpochMs: row.updatedAtEpochMs,
      syncStatus: row.syncStatus,
      attemptCount: row.attemptCount,
      lastAttemptAtEpochMs: row.lastAttemptAtEpochMs,
      lastErrorCategory: row.lastErrorCategory,
      lastErrorMessage: row.lastErrorMessage,
      fieldErrorsJson: row.fieldErrorsJson,
      payloadJson: row.payloadJson,
      headOfFamilyName: row.headOfFamilyName,
      memberCount: row.memberCount,
      barangayName: row.barangayName,
      ownerStaffId: row.ownerStaffId,
    );
  }
}
