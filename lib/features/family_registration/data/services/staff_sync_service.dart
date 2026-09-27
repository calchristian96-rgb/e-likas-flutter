import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../ec_board/domain/entities/ec_board_entry_draft.dart'
    show HouseholdMode;
import '../../../ec_board/domain/repositories/ec_board_repository.dart';
import '../../domain/entities/pending_registration_status.dart';
import '../../domain/repositories/family_registration_repository.dart';
import '../../domain/repositories/pending_queue_repository.dart';

class StaffSyncRunResult {
  const StaffSyncRunResult({
    required this.processed,
    required this.stoppedForAuth,
    this.wasOffline = false,
  });

  final int processed;

  /// True when the run stopped early because a request came back 401
  /// — the caller (the sync-trigger provider) surfaces "session
  /// expired, sign in again" and the remaining queue is untouched.
  final bool stoppedForAuth;

  /// True when there was no connection at all the moment this run
  /// started — nothing was attempted. Distinct from [processed] being
  /// 0 for an ordinary "already up to date" run: the caller uses this
  /// to show "you're offline" rather than a misleadingly-generic
  /// "0 synced" message that reads the same as genuinely having
  /// nothing pending.
  final bool wasOffline;
}

/// Processes the pending queue **sequentially, never concurrently**
/// (explicit task requirement — no parallel `POST`s), applying the
/// exact status-transition rules from the task spec:
///
/// pending → syncing → `POST /families/register` →
///   - 201  → synced (payload deleted)
///   - 422  → needsAttention, editable, field errors preserved
///   - 401  → stop the whole run, require re-login
///   - 403  → needsAttention, never auto-retried
///   - offline / 5xx / plain timeout → pending (retryable later)
///   - receiveTimeout ([AmbiguousWriteFailure]) → needsAttention,
///     since the backend has no idempotency protection and an
///     auto-retry here could create a duplicate family
///
/// Then, in the same run, EC Board entries — **always after** every
/// family registration, mirroring the desktop app's proven ordering:
/// an "existing household" EC Board entry may reference a family that
/// was itself only a local pending registration when queued, so every
/// family must get its chance to become a real backend id first (see
/// [_promoteHouseholdReferences]) before any EC Board entry pointing
/// at it can possibly sync.
class StaffSyncService {
  StaffSyncService({
    required PendingQueueRepository pendingQueueRepository,
    required FamilyRegistrationRepository registrationRepository,
    required ConnectivityService connectivity,
    EcBoardRepository? ecBoardRepository,
  }) : _pendingQueueRepository = pendingQueueRepository,
       _registrationRepository = registrationRepository,
       _connectivity = connectivity,
       _ecBoardRepository = ecBoardRepository;

  final PendingQueueRepository _pendingQueueRepository;
  final FamilyRegistrationRepository _registrationRepository;
  final ConnectivityService _connectivity;

  /// Nullable rather than required: a signed-out/unresolved session
  /// has no owner id to scope an EC Board queue to (see
  /// `ecBoardRepositoryProvider`) — [run] simply skips the EC Board
  /// phase entirely when this is null, same as the family queue
  /// naturally has nothing to process for a session with no owner id.
  final EcBoardRepository? _ecBoardRepository;

  bool _running = false;

  Future<StaffSyncRunResult> run() async {
    if (_running) {
      return const StaffSyncRunResult(processed: 0, stoppedForAuth: false);
    }
    if (!await _connectivity.hasConnection) {
      return const StaffSyncRunResult(
        processed: 0,
        stoppedForAuth: false,
        wasOffline: true,
      );
    }
    _running = true;
    try {
      final familyResult = await _runFamilyQueue();
      if (familyResult.stoppedForAuth) return familyResult;

      return await _runEcBoardQueue(familyResult.processed);
    } finally {
      _running = false;
    }
  }

  /// Pushes only pending family registrations — used by Registered
  /// Families' own "Sync Now" next to its "Not yet synced" section,
  /// same "don't push what the staff member isn't looking at" reasoning
  /// as [syncEcBoardEntriesOnly]. Still promotes any EC Board entry
  /// that referenced a family synced here (a cheap local rewrite, not a
  /// push) so that entry is ready the next time EC Board syncs.
  Future<StaffSyncRunResult> syncFamilyRegistrationsOnly() async {
    if (_running) {
      return const StaffSyncRunResult(processed: 0, stoppedForAuth: false);
    }
    if (!await _connectivity.hasConnection) {
      return const StaffSyncRunResult(
        processed: 0,
        stoppedForAuth: false,
        wasOffline: true,
      );
    }
    _running = true;
    try {
      return await _runFamilyQueue();
    } finally {
      _running = false;
    }
  }

  Future<StaffSyncRunResult> _runFamilyQueue() async {
    var processed = 0;
    final queue = await _pendingQueueRepository.getPendingQueueInOrder();

    for (final item in queue) {
      final localId = item.summary.localId;

      // Checked before every single item, not just once at the start
      // of the run — connectivity can drop mid-run on a real device,
      // and there's no reason to attempt an item that's already
      // known-doomed.
      if (!await _connectivity.hasConnection) break;

      await _pendingQueueRepository.markSyncing(localId);
      final result = await _registrationRepository.submit(item.draft);

      switch (result) {
        case Success(:final value):
          await _pendingQueueRepository.markSynced(localId);
          await _promoteHouseholdReferences(
            familyLocalId: localId,
            remoteFamilyId: value,
          );
          processed++;
        case Failed(:final failure):
          if (failure is AuthFailure) {
            await _pendingQueueRepository.markRetryLater(
              localId,
              message: failure.message,
            );
            return StaffSyncRunResult(
              processed: processed,
              stoppedForAuth: true,
            );
          }
          await _applyFailure(localId, failure);
      }
    }

    return StaffSyncRunResult(processed: processed, stoppedForAuth: false);
  }

  /// Pushes only the EC Board evacuee queue — used by EC Board's own
  /// "Sync Now" next to its pending evacuees, so tapping it doesn't
  /// also push family registrations the staff member wasn't
  /// looking at. Deliberately doesn't run the
  /// family-registration phase first: an entry still referencing a
  /// not-yet-synced family registration is simply left `pending` by
  /// [_runEcBoardQueue]'s own `isReadyToSync` check, exactly as if
  /// this were partway through [run] — it becomes syncable once that
  /// registration itself syncs (from Pending Registrations, or the
  /// next full [run]), not silently dropped.
  Future<StaffSyncRunResult> syncEcBoardEntriesOnly() async {
    if (_running) {
      return const StaffSyncRunResult(processed: 0, stoppedForAuth: false);
    }
    if (!await _connectivity.hasConnection) {
      return const StaffSyncRunResult(
        processed: 0,
        stoppedForAuth: false,
        wasOffline: true,
      );
    }
    _running = true;
    try {
      return await _runEcBoardQueue(0);
    } finally {
      _running = false;
    }
  }

  /// Once a pending family registration syncs, any EC Board entry
  /// still referencing it by [familyLocalId] (rather than a real
  /// backend id) is rewritten to point at [remoteFamilyId] instead —
  /// making it syncable in the very same run's EC Board phase below.
  Future<void> _promoteHouseholdReferences({
    required String familyLocalId,
    required int remoteFamilyId,
  }) async {
    final ecBoard = _ecBoardRepository;
    if (ecBoard == null) return;
    await ecBoard.promoteHouseholdReference(
      familyLocalId: familyLocalId,
      remoteFamilyId: remoteFamilyId,
    );
  }

  Future<StaffSyncRunResult> _runEcBoardQueue(int processedSoFar) async {
    final ecBoard = _ecBoardRepository;
    if (ecBoard == null) {
      return StaffSyncRunResult(
        processed: processedSoFar,
        stoppedForAuth: false,
      );
    }

    var processed = processedSoFar;
    final queue = await ecBoard.getPendingQueueInOrder();

    for (final queuedItem in queue) {
      final localId = queuedItem.summary.localId;
      if (!await _connectivity.hasConnection) break;

      // Re-fetched fresh rather than trusting `queuedItem` (captured
      // once, before this loop started): a sibling entry queued
      // against *this device's own* not-yet-synced new household
      // (see `EcBoardSubmitResult`'s doc comment) can be promoted from
      // `existingFamilyLocalId` to a real `existingFamilyRemoteId` by
      // an earlier iteration of this very loop, and that promotion
      // must be visible to the very next `isReadyToSync` check for
      // both to sync in the same run rather than needing a second
      // Sync Now tap.
      final item = await ecBoard.getDetail(localId) ?? queuedItem;

      // An existing-household entry whose family hasn't synced yet
      // (still only a local reference) isn't ready — left `pending`
      // rather than attempted and rejected by the backend, since the
      // client already knows this attempt can't succeed.
      if (!item.draft.isReadyToSync) continue;

      await ecBoard.markSyncing(localId);
      final result = await ecBoard.submit(item.draft);

      switch (result) {
        case Success(:final value):
          await ecBoard.markSynced(localId);
          // A brand-new household just got a real backend id — any
          // other pending entry still referencing *this* entry's own
          // local id (see `EcBoardEntryDraft.existingFamilyLocalId`'s
          // doc comment) can now be promoted too, same mechanism as a
          // synced family registration promoting its own references.
          if (item.draft.householdMode == HouseholdMode.new_) {
            await ecBoard.promoteHouseholdReference(
              familyLocalId: localId,
              remoteFamilyId: value.familyId,
            );
          }
          processed++;
        case Failed(:final failure):
          if (failure is AuthFailure) {
            await ecBoard.markRetryLater(localId, message: failure.message);
            return StaffSyncRunResult(
              processed: processed,
              stoppedForAuth: true,
            );
          }
          await _applyEcBoardFailure(ecBoard, localId, failure);
      }
    }

    return StaffSyncRunResult(processed: processed, stoppedForAuth: false);
  }

  Future<void> _applyEcBoardFailure(
    EcBoardRepository ecBoard,
    String localId,
    Failure failure,
  ) async {
    switch (failure) {
      case ValidationFailure():
        await ecBoard.markNeedsAttention(
          localId,
          category: PendingErrorCategory.validation,
          message: failure.message,
        );
      case ForbiddenFailure():
        await ecBoard.markNeedsAttention(
          localId,
          category: PendingErrorCategory.forbidden,
          message: failure.message,
        );
      case AmbiguousWriteFailure():
        // The POST may have already reached the server — same
        // no-idempotency reasoning as the family-registration path,
        // so this requires an explicit manual retry too.
        await ecBoard.markNeedsAttention(
          localId,
          category: PendingErrorCategory.ambiguous,
          message: failure.message,
        );
      case RateLimitFailure():
      case NetworkFailure():
      case ServerFailure():
        await ecBoard.markRetryLater(localId, message: failure.message);
      default:
        await ecBoard.markNeedsAttention(
          localId,
          category: PendingErrorCategory.server,
          message: failure.message,
        );
    }
  }

  Future<void> _applyFailure(String localId, Failure failure) async {
    switch (failure) {
      case ValidationFailure(:final fieldErrors):
        await _pendingQueueRepository.markNeedsAttention(
          localId,
          category: PendingErrorCategory.validation,
          message: failure.message,
          fieldErrors: fieldErrors,
        );
      case ForbiddenFailure():
        await _pendingQueueRepository.markNeedsAttention(
          localId,
          category: PendingErrorCategory.forbidden,
          message: failure.message,
        );
      case AmbiguousWriteFailure():
        await _pendingQueueRepository.markNeedsAttention(
          localId,
          category: PendingErrorCategory.ambiguous,
          message: failure.message,
        );
      case RateLimitFailure():
      case NetworkFailure():
      case ServerFailure():
        await _pendingQueueRepository.markRetryLater(
          localId,
          message: failure.message,
        );
      default:
        // CacheFailure/LocationFailure/AuthFailure can't actually
        // reach here (AuthFailure is handled in [run] before this is
        // called) — kept as a safety net rather than left unhandled.
        await _pendingQueueRepository.markNeedsAttention(
          localId,
          category: PendingErrorCategory.server,
          message: failure.message,
        );
    }
  }
}
