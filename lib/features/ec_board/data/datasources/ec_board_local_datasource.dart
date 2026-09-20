import 'package:drift/drift.dart';

import '../../../../core/database/staff_database.dart';
import '../models/pending_ec_board_entry_model.dart';
import '../models/pending_quick_count_edit_model.dart';

/// Drift-backed CRUD over the EC Board offline queue, in the encrypted
/// staff [StaffDatabase] — mirrors `PendingQueueLocalDataSource`
/// exactly (no legacy-Isar bridge here: this dataset never existed
/// before Drift, so there's nothing to migrate).
class EcBoardLocalDataSource {
  const EcBoardLocalDataSource(this._db);

  final StaffDatabase _db;

  Future<List<PendingEcBoardEntryModel>> getAll() async {
    final rows = await _db.select(_db.pendingEcBoardEntries).get();
    return rows.map(_fromRow).toList();
  }

  Future<PendingEcBoardEntryModel?> getByLocalId(String localId) async {
    final row = await (_db.select(
      _db.pendingEcBoardEntries,
    )..where((t) => t.localId.equals(localId))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<void> put(PendingEcBoardEntryModel model) async {
    await _db
        .into(_db.pendingEcBoardEntries)
        .insertOnConflictUpdate(_toCompanion(model));
  }

  Future<void> delete(String localId) async {
    await (_db.delete(
      _db.pendingEcBoardEntries,
    )..where((t) => t.localId.equals(localId))).go();
  }

  /// Every entry whose `existingFamilyLocalId` equals [familyLocalId]
  /// — used by `EcBoardRepositoryImpl.promoteHouseholdReference` to
  /// find what to rewrite once that local family registration syncs.
  Future<List<PendingEcBoardEntryModel>> getByExistingFamilyLocalId(
    String familyLocalId,
  ) async {
    final rows = await (_db.select(
      _db.pendingEcBoardEntries,
    )..where((t) => t.existingFamilyLocalId.equals(familyLocalId))).get();
    return rows.map(_fromRow).toList();
  }

  static PendingEcBoardEntriesCompanion _toCompanion(
    PendingEcBoardEntryModel m,
  ) {
    return PendingEcBoardEntriesCompanion.insert(
      localId: m.localId,
      evacuationCenterId: m.evacuationCenterId,
      evacuationEventId: m.evacuationEventId,
      sex: m.sex,
      ageBracket: m.ageBracket,
      householdMode: m.householdMode,
      existingFamilyRemoteId: Value(m.existingFamilyRemoteId),
      existingFamilyLocalId: Value(m.existingFamilyLocalId),
      newHouseholdHeadName: Value(m.newHouseholdHeadName),
      newHouseholdBarangayId: Value(m.newHouseholdBarangayId),
      householdLabel: m.householdLabel,
      syncStatus: m.syncStatus,
      attemptCount: Value(m.attemptCount),
      lastAttemptAtEpochMs: Value(m.lastAttemptAtEpochMs),
      lastErrorCategory: Value(m.lastErrorCategory),
      lastErrorMessage: Value(m.lastErrorMessage),
      createdAtEpochMs: m.createdAtEpochMs,
      updatedAtEpochMs: m.updatedAtEpochMs,
      ownerStaffId: Value(m.ownerStaffId),
    );
  }

  static PendingEcBoardEntryModel _fromRow(PendingEcBoardEntryRow row) {
    return PendingEcBoardEntryModel(
      localId: row.localId,
      evacuationCenterId: row.evacuationCenterId,
      evacuationEventId: row.evacuationEventId,
      sex: row.sex,
      ageBracket: row.ageBracket,
      householdMode: row.householdMode,
      existingFamilyRemoteId: row.existingFamilyRemoteId,
      existingFamilyLocalId: row.existingFamilyLocalId,
      newHouseholdHeadName: row.newHouseholdHeadName,
      newHouseholdBarangayId: row.newHouseholdBarangayId,
      householdLabel: row.householdLabel,
      syncStatus: row.syncStatus,
      attemptCount: row.attemptCount,
      lastAttemptAtEpochMs: row.lastAttemptAtEpochMs,
      lastErrorCategory: row.lastErrorCategory,
      lastErrorMessage: row.lastErrorMessage,
      createdAtEpochMs: row.createdAtEpochMs,
      updatedAtEpochMs: row.updatedAtEpochMs,
      ownerStaffId: row.ownerStaffId,
    );
  }

  // --- PendingQuickCountEdits: one mutable row per (center, event,
  // --- owner) — see that table's own doc comment.

  Future<List<PendingQuickCountEditModel>> getAllQuickCountEdits() async {
    final rows = await _db.select(_db.pendingQuickCountEdits).get();
    return rows.map(_quickCountEditFromRow).toList();
  }

  Future<PendingQuickCountEditModel?> getQuickCountEdit({
    required int centerId,
    required int evacuationEventId,
    required int ownerStaffId,
  }) async {
    final row =
        await (_db.select(_db.pendingQuickCountEdits)..where(
              (t) =>
                  t.evacuationCenterId.equals(centerId) &
                  t.evacuationEventId.equals(evacuationEventId) &
                  t.ownerStaffId.equals(ownerStaffId),
            ))
            .getSingleOrNull();
    return row == null ? null : _quickCountEditFromRow(row);
  }

  Future<void> putQuickCountEdit(PendingQuickCountEditModel model) async {
    await _db
        .into(_db.pendingQuickCountEdits)
        .insertOnConflictUpdate(_quickCountEditToCompanion(model));
  }

  Future<void> deleteQuickCountEdit({
    required int centerId,
    required int evacuationEventId,
    required int ownerStaffId,
  }) async {
    await (_db.delete(_db.pendingQuickCountEdits)..where(
          (t) =>
              t.evacuationCenterId.equals(centerId) &
              t.evacuationEventId.equals(evacuationEventId) &
              t.ownerStaffId.equals(ownerStaffId),
        ))
        .go();
  }

  static PendingQuickCountEditsCompanion _quickCountEditToCompanion(
    PendingQuickCountEditModel m,
  ) {
    return PendingQuickCountEditsCompanion.insert(
      evacuationCenterId: m.evacuationCenterId,
      evacuationEventId: m.evacuationEventId,
      ownerStaffId: m.ownerStaffId,
      beneficiaries4ps: m.beneficiaries4ps,
      sectoralGroupsJson: PendingQuickCountEditModel.encodeSectoralGroups(
        m.sectoralGroups,
      ),
      syncStatus: m.syncStatus,
      attemptCount: Value(m.attemptCount),
      lastAttemptAtEpochMs: Value(m.lastAttemptAtEpochMs),
      lastErrorCategory: Value(m.lastErrorCategory),
      lastErrorMessage: Value(m.lastErrorMessage),
      createdAtEpochMs: m.createdAtEpochMs,
      updatedAtEpochMs: m.updatedAtEpochMs,
    );
  }

  static PendingQuickCountEditModel _quickCountEditFromRow(
    PendingQuickCountEditRow row,
  ) {
    return PendingQuickCountEditModel(
      evacuationCenterId: row.evacuationCenterId,
      evacuationEventId: row.evacuationEventId,
      ownerStaffId: row.ownerStaffId,
      beneficiaries4ps: row.beneficiaries4ps,
      sectoralGroups: PendingQuickCountEditModel.decodeSectoralGroups(
        row.sectoralGroupsJson,
      ),
      syncStatus: row.syncStatus,
      attemptCount: row.attemptCount,
      lastAttemptAtEpochMs: row.lastAttemptAtEpochMs,
      lastErrorCategory: row.lastErrorCategory,
      lastErrorMessage: row.lastErrorMessage,
      createdAtEpochMs: row.createdAtEpochMs,
      updatedAtEpochMs: row.updatedAtEpochMs,
    );
  }
}
