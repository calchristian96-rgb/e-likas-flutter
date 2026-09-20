import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/result.dart';
import '../../../../core/network/staff_api_error_mapper.dart';
import '../../../family_registration/domain/entities/pending_registration_status.dart';
import '../../domain/entities/age_bracket.dart';
import '../../domain/entities/ec_board_entry_draft.dart';
import '../../domain/entities/ec_board_quick_count.dart';
import '../../domain/entities/pending_ec_board_entry.dart';
import '../../domain/entities/pending_quick_count_edit.dart';
import '../../domain/entities/quick_departure_request.dart';
import '../../domain/entities/sectoral_group_draft.dart';
import '../../domain/repositories/ec_board_repository.dart';
import '../datasources/ec_board_local_datasource.dart';
import '../datasources/ec_board_remote_datasource.dart';
import '../models/pending_ec_board_entry_model.dart';
import '../models/pending_quick_count_edit_model.dart';

/// Every read/write here is scoped to [_ownerStaffId] — same ownership
/// rule as `PendingQueueRepositoryImpl`, so one staff account can never
/// see, sync, edit, or delete another's queued entries on a shared
/// device.
class EcBoardRepositoryImpl implements EcBoardRepository {
  EcBoardRepositoryImpl(this._local, this._remote, {this._ownerStaffId});

  final EcBoardLocalDataSource _local;
  final EcBoardRemoteDataSource _remote;
  final int? _ownerStaffId;

  static const _uuid = Uuid();

  @override
  Future<List<PendingEcBoardEntrySummary>> getAllForCenter(int centerId) async {
    final models = await _ownedModelsForCenter(centerId);
    final summaries = models.map(_toSummary).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return summaries;
  }

  @override
  Future<List<PendingEcBoardEntrySummary>> getPendingNewHouseholds({
    required int centerId,
    required int evacuationEventId,
  }) async {
    final owned = await _ownedModelsForCenter(centerId);
    final newHouseholds = owned
        .where((m) => m.evacuationEventId == evacuationEventId)
        .where((m) => HouseholdMode.fromWire(m.householdMode) == HouseholdMode.new_)
        .toList()
      ..sort((a, b) => b.createdAtEpochMs.compareTo(a.createdAtEpochMs));
    return newHouseholds.map(_toSummary).toList();
  }

  @override
  Future<PendingEcBoardEntryDetail?> getDetail(String localId) async {
    final model = _owned(await _local.getByLocalId(localId));
    return model == null ? null : _toDetail(model);
  }

  @override
  Future<String> enqueue(
    EcBoardEntryDraft draft, {
    required String householdLabel,
  }) async {
    final localId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _local.put(
      PendingEcBoardEntryModel(
        localId: localId,
        evacuationCenterId: draft.evacuationCenterId,
        evacuationEventId: draft.evacuationEventId!,
        sex: draft.sex!,
        ageBracket: draft.ageBracket!.wireValue,
        householdMode: draft.householdMode.wireValue,
        existingFamilyRemoteId: draft.existingFamilyRemoteId,
        existingFamilyLocalId: draft.existingFamilyLocalId,
        newHouseholdHeadName: draft.newHouseholdHeadName,
        newHouseholdBarangayId: draft.newHouseholdBarangayId,
        householdLabel: householdLabel,
        syncStatus: PendingRegistrationStatus.pending.wireValue,
        createdAtEpochMs: now,
        updatedAtEpochMs: now,
        ownerStaffId: _ownerStaffId,
      ),
    );
    return localId;
  }

  @override
  Future<void> updateDraft(
    String localId,
    EcBoardEntryDraft draft, {
    required String householdLabel,
  }) async {
    final existing = _owned(await _local.getByLocalId(localId));
    if (existing == null) return;
    await _local.put(
      existing.copyWith(
        evacuationEventId: draft.evacuationEventId,
        sex: draft.sex,
        ageBracket: draft.ageBracket?.wireValue,
        householdMode: draft.householdMode.wireValue,
        existingFamilyRemoteId: draft.existingFamilyRemoteId,
        clearExistingFamilyRemoteId: draft.existingFamilyRemoteId == null,
        existingFamilyLocalId: draft.existingFamilyLocalId,
        clearExistingFamilyLocalId: draft.existingFamilyLocalId == null,
        newHouseholdHeadName: draft.newHouseholdHeadName,
        newHouseholdBarangayId: draft.newHouseholdBarangayId,
        householdLabel: householdLabel,
        syncStatus: PendingRegistrationStatus.pending.wireValue,
        updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> delete(String localId) async {
    final existing = _owned(await _local.getByLocalId(localId));
    if (existing == null) return;
    await _local.delete(localId);
  }

  @override
  Future<EcBoardQueueCounts> getCountsForCenter(int centerId) async {
    final models = await _ownedModelsForCenter(centerId);
    var pending = 0;
    var needsAttention = 0;
    for (final m in models) {
      final status = PendingRegistrationStatus.fromWire(m.syncStatus);
      if (status == PendingRegistrationStatus.needsAttention) {
        needsAttention++;
      } else {
        pending++;
      }
    }
    return EcBoardQueueCounts(pending: pending, needsAttention: needsAttention);
  }

  @override
  Future<void> markSyncing(String localId) async {
    final existing = _owned(await _local.getByLocalId(localId));
    if (existing == null) return;
    await _local.put(
      existing.copyWith(
        syncStatus: PendingRegistrationStatus.syncing.wireValue,
        updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> markSynced(String localId) async {
    final existing = _owned(await _local.getByLocalId(localId));
    if (existing == null) return;
    await _local.delete(localId);
  }

  @override
  Future<void> markNeedsAttention(
    String localId, {
    required PendingErrorCategory category,
    required String message,
  }) async {
    final existing = _owned(await _local.getByLocalId(localId));
    if (existing == null) return;
    await _local.put(
      existing.copyWith(
        syncStatus: PendingRegistrationStatus.needsAttention.wireValue,
        attemptCount: existing.attemptCount + 1,
        lastAttemptAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        lastErrorCategory: category.wireValue,
        lastErrorMessage: message,
        updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> markRetryLater(String localId, {required String message}) async {
    final existing = _owned(await _local.getByLocalId(localId));
    if (existing == null) return;
    await _local.put(
      existing.copyWith(
        syncStatus: PendingRegistrationStatus.pending.wireValue,
        attemptCount: existing.attemptCount + 1,
        lastAttemptAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        lastErrorMessage: message,
        updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<List<PendingEcBoardEntryDetail>> getPendingQueueInOrder() async {
    final owned = await _ownedModels();
    final pending =
        owned
            .where(
              (m) =>
                  PendingRegistrationStatus.fromWire(m.syncStatus) ==
                  PendingRegistrationStatus.pending,
            )
            .toList()
          ..sort((a, b) => a.createdAtEpochMs.compareTo(b.createdAtEpochMs));
    return pending.map(_toDetail).toList();
  }

  @override
  Future<void> promoteHouseholdReference({
    required String familyLocalId,
    required int remoteFamilyId,
  }) async {
    final matches = await _local.getByExistingFamilyLocalId(familyLocalId);
    for (final entry in matches) {
      if (entry.ownerStaffId != _ownerStaffId) continue;
      await _local.put(
        entry.copyWith(
          existingFamilyRemoteId: remoteFamilyId,
          clearExistingFamilyLocalId: true,
          updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
  }

  @override
  Future<Result<EcBoardQuickCount>> getQuickCount({
    required int centerId,
    required int evacuationEventId,
  }) async {
    try {
      final count = await _remote.getQuickCount(
        centerId: centerId,
        evacuationEventId: evacuationEventId,
      );
      await _local.cacheQuickCount(
        centerId: centerId,
        evacuationEventId: evacuationEventId,
        count: count,
      );
      return Success(count);
    } on DioException catch (e) {
      final cached = await _local.getCachedQuickCount(
        centerId: centerId,
        evacuationEventId: evacuationEventId,
      );
      if (cached != null) return Success(cached);
      return Failed(mapStaffDioError(e));
    }
  }

  @override
  Future<Result<EcBoardSubmitResult>> submit(EcBoardEntryDraft draft) async {
    try {
      final result = await _remote.createEvacuee(
        draft.evacuationCenterId,
        draft.toJson(),
      );
      return Success(result);
    } on DioException catch (e) {
      return Failed(mapStaffDioError(e));
    }
  }

  // --- Sectoral/4Ps edit ---

  @override
  Future<PendingQuickCountEditDetail?> getPendingQuickCountEdit({
    required int centerId,
    required int evacuationEventId,
  }) async {
    final ownerStaffId = _ownerStaffId;
    if (ownerStaffId == null) return null;
    final model = await _local.getQuickCountEdit(
      centerId: centerId,
      evacuationEventId: evacuationEventId,
      ownerStaffId: ownerStaffId,
    );
    return model == null ? null : _toQuickCountEditDetail(model);
  }

  @override
  Future<void> saveQuickCountEdit(SectoralGroupDraft draft) async {
    final ownerStaffId = _ownerStaffId;
    if (ownerStaffId == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await _local.getQuickCountEdit(
      centerId: draft.evacuationCenterId,
      evacuationEventId: draft.evacuationEventId,
      ownerStaffId: ownerStaffId,
    );
    await _local.putQuickCountEdit(
      PendingQuickCountEditModel(
        evacuationCenterId: draft.evacuationCenterId,
        evacuationEventId: draft.evacuationEventId,
        ownerStaffId: ownerStaffId,
        beneficiaries4ps: draft.beneficiaries4ps,
        sectoralGroups: draft.sectoralGroups,
        syncStatus: PendingRegistrationStatus.pending.wireValue,
        createdAtEpochMs: existing?.createdAtEpochMs ?? now,
        updatedAtEpochMs: now,
      ),
    );
  }

  @override
  Future<void> deleteQuickCountEdit({
    required int centerId,
    required int evacuationEventId,
  }) async {
    final ownerStaffId = _ownerStaffId;
    if (ownerStaffId == null) return;
    await _local.deleteQuickCountEdit(
      centerId: centerId,
      evacuationEventId: evacuationEventId,
      ownerStaffId: ownerStaffId,
    );
  }

  @override
  Future<void> markQuickCountEditSyncing({
    required int centerId,
    required int evacuationEventId,
  }) async {
    final existing = await _ownedQuickCountEdit(centerId, evacuationEventId);
    if (existing == null) return;
    await _local.putQuickCountEdit(
      existing.copyWith(
        syncStatus: PendingRegistrationStatus.syncing.wireValue,
        updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> markQuickCountEditSynced({
    required int centerId,
    required int evacuationEventId,
  }) async {
    final ownerStaffId = _ownerStaffId;
    if (ownerStaffId == null) return;
    final existing = await _ownedQuickCountEdit(centerId, evacuationEventId);
    if (existing == null) return;
    await _local.deleteQuickCountEdit(
      centerId: centerId,
      evacuationEventId: evacuationEventId,
      ownerStaffId: ownerStaffId,
    );
  }

  @override
  Future<void> markQuickCountEditNeedsAttention({
    required int centerId,
    required int evacuationEventId,
    required PendingErrorCategory category,
    required String message,
  }) async {
    final existing = await _ownedQuickCountEdit(centerId, evacuationEventId);
    if (existing == null) return;
    await _local.putQuickCountEdit(
      existing.copyWith(
        syncStatus: PendingRegistrationStatus.needsAttention.wireValue,
        attemptCount: existing.attemptCount + 1,
        lastAttemptAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        lastErrorCategory: category.wireValue,
        lastErrorMessage: message,
        updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> markQuickCountEditRetryLater({
    required int centerId,
    required int evacuationEventId,
    required String message,
  }) async {
    final existing = await _ownedQuickCountEdit(centerId, evacuationEventId);
    if (existing == null) return;
    await _local.putQuickCountEdit(
      existing.copyWith(
        syncStatus: PendingRegistrationStatus.pending.wireValue,
        attemptCount: existing.attemptCount + 1,
        lastAttemptAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        lastErrorMessage: message,
        updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<List<PendingQuickCountEditDetail>>
  getPendingQuickCountEditQueue() async {
    final ownerStaffId = _ownerStaffId;
    if (ownerStaffId == null) return const [];
    final all = await _local.getAllQuickCountEdits();
    final owned = all
        .where((m) => m.ownerStaffId == ownerStaffId)
        .where(
          (m) =>
              PendingRegistrationStatus.fromWire(m.syncStatus) ==
              PendingRegistrationStatus.pending,
        )
        .toList()
      ..sort((a, b) => a.createdAtEpochMs.compareTo(b.createdAtEpochMs));
    return owned.map(_toQuickCountEditDetail).toList();
  }

  @override
  Future<Result<EcBoardQuickCount>> updateQuickCount(
    SectoralGroupDraft draft,
  ) async {
    try {
      final count = await _remote.updateQuickCount(
        draft.evacuationCenterId,
        draft,
      );
      return Success(count);
    } on DioException catch (e) {
      return Failed(mapStaffDioError(e));
    }
  }

  @override
  Future<Result<String>> quickDeparture(QuickDepartureRequest request) async {
    try {
      final message = await _remote.quickDeparture(request);
      return Success(message);
    } on DioException catch (e) {
      return Failed(mapStaffDioError(e));
    }
  }

  Future<PendingQuickCountEditModel?> _ownedQuickCountEdit(
    int centerId,
    int evacuationEventId,
  ) async {
    final ownerStaffId = _ownerStaffId;
    if (ownerStaffId == null) return null;
    return _local.getQuickCountEdit(
      centerId: centerId,
      evacuationEventId: evacuationEventId,
      ownerStaffId: ownerStaffId,
    );
  }

  PendingQuickCountEditDetail _toQuickCountEditDetail(
    PendingQuickCountEditModel m,
  ) {
    return PendingQuickCountEditDetail(
      summary: PendingQuickCountEditSummary(
        evacuationCenterId: m.evacuationCenterId,
        evacuationEventId: m.evacuationEventId,
        status: PendingRegistrationStatus.fromWire(m.syncStatus),
        beneficiaries4ps: m.beneficiaries4ps,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m.createdAtEpochMs),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m.updatedAtEpochMs),
        attemptCount: m.attemptCount,
        lastErrorCategory: m.lastErrorCategory == null
            ? null
            : PendingErrorCategory.fromWire(m.lastErrorCategory!),
        lastErrorMessage: m.lastErrorMessage,
      ),
      draft: SectoralGroupDraft(
        evacuationCenterId: m.evacuationCenterId,
        evacuationEventId: m.evacuationEventId,
        beneficiaries4ps: m.beneficiaries4ps,
        sectoralGroups: m.sectoralGroups,
      ),
    );
  }

  Future<List<PendingEcBoardEntryModel>> _ownedModels() async {
    if (_ownerStaffId == null) return const [];
    final all = await _local.getAll();
    return all.where((m) => m.ownerStaffId == _ownerStaffId).toList();
  }

  Future<List<PendingEcBoardEntryModel>> _ownedModelsForCenter(
    int centerId,
  ) async {
    final owned = await _ownedModels();
    return owned.where((m) => m.evacuationCenterId == centerId).toList();
  }

  PendingEcBoardEntryModel? _owned(PendingEcBoardEntryModel? model) {
    if (model == null || _ownerStaffId == null) return null;
    if (model.ownerStaffId != _ownerStaffId) return null;
    return model;
  }

  PendingEcBoardEntrySummary _toSummary(PendingEcBoardEntryModel m) {
    return PendingEcBoardEntrySummary(
      localId: m.localId,
      evacuationCenterId: m.evacuationCenterId,
      evacuationEventId: m.evacuationEventId,
      status: PendingRegistrationStatus.fromWire(m.syncStatus),
      sex: m.sex,
      ageBracket: AgeBracket.fromWire(m.ageBracket),
      householdLabel: m.householdLabel,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m.createdAtEpochMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m.updatedAtEpochMs),
      attemptCount: m.attemptCount,
      lastErrorCategory: m.lastErrorCategory == null
          ? null
          : PendingErrorCategory.fromWire(m.lastErrorCategory!),
      lastErrorMessage: m.lastErrorMessage,
    );
  }

  PendingEcBoardEntryDetail _toDetail(PendingEcBoardEntryModel m) {
    return PendingEcBoardEntryDetail(
      summary: _toSummary(m),
      draft: EcBoardEntryDraft(
        evacuationCenterId: m.evacuationCenterId,
        evacuationEventId: m.evacuationEventId,
        sex: m.sex,
        ageBracket: AgeBracket.fromWire(m.ageBracket),
        householdMode: HouseholdMode.fromWire(m.householdMode),
        existingFamilyRemoteId: m.existingFamilyRemoteId,
        existingFamilyLocalId: m.existingFamilyLocalId,
        newHouseholdHeadName: m.newHouseholdHeadName,
        newHouseholdBarangayId: m.newHouseholdBarangayId,
      ),
    );
  }
}
