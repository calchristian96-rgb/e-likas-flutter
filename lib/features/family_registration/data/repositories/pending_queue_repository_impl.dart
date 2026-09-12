import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../../core/debug/pending_count_debug_log.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/family_registration_draft.dart';
import '../../domain/entities/pending_registration.dart';
import '../../domain/entities/pending_registration_status.dart';
import '../../domain/repositories/lookup_repository.dart';
import '../../domain/repositories/pending_queue_repository.dart';
import '../datasources/pending_queue_local_datasource.dart';
import '../models/pending_family_registration_model.dart';

/// Every read/write here is scoped to [_ownerStaffId] — the real
/// backend user id of whichever staff member is currently signed in
/// (see `pendingQueueRepositoryProvider`, which rebuilds this whole
/// repository whenever the signed-in account changes). One staff
/// account can never see, sync, edit, or delete another's queued
/// registrations through this repository, even on a shared device,
/// and switching accounts never deletes anyone's queue — it just
/// changes which slice of it this repository instance can reach.
class PendingQueueRepositoryImpl implements PendingQueueRepository {
  PendingQueueRepositoryImpl(
    this._local,
    this._lookupRepository, {
    required int? ownerStaffId,
  }) : _ownerStaffId = ownerStaffId;

  final PendingQueueLocalDataSource _local;
  final LookupRepository _lookupRepository;

  /// Null only when no staff session is currently resolved (e.g. a
  /// brief moment during app startup) — every method treats that as
  /// "no accessible queue" rather than falling back to showing
  /// everyone's records.
  final int? _ownerStaffId;

  static const _uuid = Uuid();

  bool _legacyClaimed = false;

  @override
  Future<List<PendingRegistrationSummary>> getAll() async {
    await _claimLegacyRecordsIfNeeded();
    final models = await _ownedModels();
    final summaries = models.map(_toSummary).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return summaries;
  }

  @override
  Future<PendingRegistrationDetail?> getDetail(String localId) async {
    await _claimLegacyRecordsIfNeeded();
    final model = _owned(await _local.getByLocalId(localId));
    return model == null ? null : _toDetail(model);
  }

  @override
  Future<String> enqueue(FamilyRegistrationDraft draft) async {
    final localId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final barangayName = await _resolveBarangayName(draft.barangayId);
    await _local.put(
      PendingFamilyRegistrationModel(
        id: fastHash(localId),
        localId: localId,
        createdAtEpochMs: now,
        updatedAtEpochMs: now,
        syncStatus: PendingRegistrationStatus.pending.wireValue,
        payloadJson: jsonEncode(draft.toJson()),
        headOfFamilyName: draft.headOfFamily?.fullName ?? '',
        memberCount: draft.members.length,
        barangayName: barangayName,
        ownerStaffId: _ownerStaffId,
      ),
    );
    return localId;
  }

  @override
  Future<void> updateDraft(
    String localId,
    FamilyRegistrationDraft draft,
  ) async {
    final existing = _owned(await _local.getByLocalId(localId));
    if (existing == null) return;
    final barangayName = await _resolveBarangayName(draft.barangayId);
    await _local.put(
      PendingFamilyRegistrationModel(
        id: existing.id,
        localId: existing.localId,
        createdAtEpochMs: existing.createdAtEpochMs,
        updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        syncStatus: PendingRegistrationStatus.pending.wireValue,
        attemptCount: existing.attemptCount,
        payloadJson: jsonEncode(draft.toJson()),
        headOfFamilyName: draft.headOfFamily?.fullName ?? '',
        memberCount: draft.members.length,
        barangayName: barangayName,
        ownerStaffId: existing.ownerStaffId,
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
  Future<PendingQueueCounts> getCounts() async {
    pendingCountDebugLog('C repository entered ownerStaffId=$_ownerStaffId');
    try {
      await _claimLegacyRecordsIfNeeded();
      final models = await _ownedModels();
      pendingCountDebugLog(
        'repository success ownedModelCount=${models.length}',
      );
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
      return PendingQueueCounts(
        pending: pending,
        needsAttention: needsAttention,
      );
    } catch (error, stackTrace) {
      pendingCountDebugLog('repository ERROR TYPE=${error.runtimeType}');
      pendingCountDebugLog('repository ERROR=$error');
      pendingCountDebugLog('repository STACK=$stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> markSyncing(String localId) async {
    final existing = _owned(await _local.getByLocalId(localId));
    if (existing == null) return;
    await _local.put(
      _copyWith(existing, syncStatus: PendingRegistrationStatus.syncing),
    );
  }

  /// Deletes the record outright — the sensitive payload's whole
  /// reason for existing (staging an unsent registration) ends the
  /// moment the backend confirms it, per the task spec's "confirm
  /// successful queue removal" test case and this model's own doc
  /// comment.
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
    Map<String, List<String>>? fieldErrors,
  }) async {
    final existing = _owned(await _local.getByLocalId(localId));
    if (existing == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _local.put(
      _copyWith(
        existing,
        syncStatus: PendingRegistrationStatus.needsAttention,
        attemptCount: existing.attemptCount + 1,
        lastAttemptAtEpochMs: now,
        lastErrorCategory: category.wireValue,
        lastErrorMessage: message,
        fieldErrorsJson: fieldErrors == null ? null : jsonEncode(fieldErrors),
      ),
    );
  }

  @override
  Future<void> markRetryLater(String localId, {required String message}) async {
    final existing = _owned(await _local.getByLocalId(localId));
    if (existing == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _local.put(
      _copyWith(
        existing,
        syncStatus: PendingRegistrationStatus.pending,
        attemptCount: existing.attemptCount + 1,
        lastAttemptAtEpochMs: now,
        lastErrorMessage: message,
      ),
    );
  }

  @override
  Future<List<PendingRegistrationDetail>> getPendingQueueInOrder() async {
    await _claimLegacyRecordsIfNeeded();
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

  /// Every locally-queued record belonging to [_ownerStaffId] — the
  /// one place every read method funnels through, so "scoped to the
  /// current staff account" only has to be gotten right once.
  Future<List<PendingFamilyRegistrationModel>> _ownedModels() async {
    if (_ownerStaffId == null) return const [];
    final all = await _local.getAll();
    return all.where((m) => m.ownerStaffId == _ownerStaffId).toList();
  }

  /// Guards every localId-keyed operation: returns [model] only if it
  /// both exists and belongs to [_ownerStaffId], otherwise null (the
  /// same result as "not found") — so a staff member who guesses or
  /// reuses another account's localId (e.g. a stale deep link) can't
  /// view, edit, delete, or otherwise affect a record they don't own.
  PendingFamilyRegistrationModel? _owned(
    PendingFamilyRegistrationModel? model,
  ) {
    if (model == null || _ownerStaffId == null) return null;
    if (model.ownerStaffId != _ownerStaffId) return null;
    return model;
  }

  /// One-time-per-repository-instance adoption of records queued
  /// before [PendingFamilyRegistrationModel.ownerStaffId] existed
  /// (`ownerStaffId == null`). Rather than losing them or leaving
  /// them permanently invisible, whichever staff account is signed in
  /// the first time this repository reads the queue after the
  /// upgrade claims them — a reasonable default for a single local,
  /// on-device queue, and it still means exactly one account owns
  /// them from that point on, so the cross-account isolation
  /// guarantee holds immediately afterward.
  Future<void> _claimLegacyRecordsIfNeeded() async {
    pendingCountDebugLog(
      'D migration check started legacyClaimed=$_legacyClaimed '
      'ownerStaffId=$_ownerStaffId',
    );
    if (_legacyClaimed || _ownerStaffId == null) {
      pendingCountDebugLog('E migration check completed (skipped)');
      return;
    }
    _legacyClaimed = true;
    final all = await _local.getAll();
    for (final model in all) {
      if (model.ownerStaffId == null) {
        await _local.put(_copyWith(model, ownerStaffId: _ownerStaffId));
      }
    }
    pendingCountDebugLog('E migration check completed claimedCount checked');
  }

  Future<String> _resolveBarangayName(int? barangayId) async {
    if (barangayId == null) return '';
    final result = await _lookupRepository.getBarangays();
    if (result case Success(:final value)) {
      for (final barangay in value) {
        if (barangay.id == barangayId) return barangay.name;
      }
    }
    return 'Barangay #$barangayId';
  }

  PendingFamilyRegistrationModel _copyWith(
    PendingFamilyRegistrationModel existing, {
    PendingRegistrationStatus? syncStatus,
    int? attemptCount,
    int? lastAttemptAtEpochMs,
    String? lastErrorCategory,
    String? lastErrorMessage,
    String? fieldErrorsJson,
    int? ownerStaffId,
  }) {
    return PendingFamilyRegistrationModel(
      id: existing.id,
      localId: existing.localId,
      createdAtEpochMs: existing.createdAtEpochMs,
      updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      syncStatus:
          (syncStatus ??
                  PendingRegistrationStatus.fromWire(existing.syncStatus))
              .wireValue,
      attemptCount: attemptCount ?? existing.attemptCount,
      lastAttemptAtEpochMs:
          lastAttemptAtEpochMs ?? existing.lastAttemptAtEpochMs,
      lastErrorCategory: lastErrorCategory ?? existing.lastErrorCategory,
      lastErrorMessage: lastErrorMessage ?? existing.lastErrorMessage,
      fieldErrorsJson: fieldErrorsJson ?? existing.fieldErrorsJson,
      payloadJson: existing.payloadJson,
      headOfFamilyName: existing.headOfFamilyName,
      memberCount: existing.memberCount,
      barangayName: existing.barangayName,
      ownerStaffId: ownerStaffId ?? existing.ownerStaffId,
    );
  }

  PendingRegistrationSummary _toSummary(PendingFamilyRegistrationModel m) {
    return PendingRegistrationSummary(
      localId: m.localId,
      status: PendingRegistrationStatus.fromWire(m.syncStatus),
      headOfFamilyName: m.headOfFamilyName,
      memberCount: m.memberCount,
      barangayName: m.barangayName,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m.createdAtEpochMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m.updatedAtEpochMs),
      attemptCount: m.attemptCount,
      lastErrorCategory: m.lastErrorCategory == null
          ? null
          : PendingErrorCategory.fromWire(m.lastErrorCategory!),
      lastErrorMessage: m.lastErrorMessage,
    );
  }

  PendingRegistrationDetail _toDetail(PendingFamilyRegistrationModel m) {
    final draft = FamilyRegistrationDraft.fromJson(
      jsonDecode(m.payloadJson) as Map<String, dynamic>,
    );
    final fieldErrors = <String, List<String>>{};
    final rawFieldErrors = m.fieldErrorsJson;
    if (rawFieldErrors != null) {
      final decoded = jsonDecode(rawFieldErrors) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        fieldErrors[entry.key] = (entry.value as List)
            .map((e) => e.toString())
            .toList();
      }
    }
    return PendingRegistrationDetail(
      summary: _toSummary(m),
      draft: draft,
      fieldErrors: fieldErrors,
    );
  }
}
