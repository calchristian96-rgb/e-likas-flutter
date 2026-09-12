import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/pending_registration_status.dart';
import '../../domain/repositories/family_registration_repository.dart';
import '../../domain/repositories/pending_queue_repository.dart';

class StaffSyncRunResult {
  const StaffSyncRunResult({
    required this.processed,
    required this.stoppedForAuth,
  });

  final int processed;

  /// True when the run stopped early because a request came back 401
  /// — the caller (the sync-trigger provider) surfaces "session
  /// expired, sign in again" and the remaining queue is untouched.
  final bool stoppedForAuth;
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
class StaffSyncService {
  StaffSyncService({
    required PendingQueueRepository pendingQueueRepository,
    required FamilyRegistrationRepository registrationRepository,
    required ConnectivityService connectivity,
  }) : _pendingQueueRepository = pendingQueueRepository,
       _registrationRepository = registrationRepository,
       _connectivity = connectivity;

  final PendingQueueRepository _pendingQueueRepository;
  final FamilyRegistrationRepository _registrationRepository;
  final ConnectivityService _connectivity;

  bool _running = false;

  Future<StaffSyncRunResult> run() async {
    if (_running) {
      return const StaffSyncRunResult(processed: 0, stoppedForAuth: false);
    }
    _running = true;
    try {
      var processed = 0;
      final queue = await _pendingQueueRepository.getPendingQueueInOrder();

      for (final item in queue) {
        final localId = item.summary.localId;

        // Checked before every single item, not just once at the
        // start of the run — connectivity can drop mid-run on a real
        // device, and there's no reason to attempt an item that's
        // already known-doomed.
        if (!await _connectivity.hasConnection) break;

        await _pendingQueueRepository.markSyncing(localId);
        final result = await _registrationRepository.submit(item.draft);

        switch (result) {
          case Success():
            await _pendingQueueRepository.markSynced(localId);
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
    } finally {
      _running = false;
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
