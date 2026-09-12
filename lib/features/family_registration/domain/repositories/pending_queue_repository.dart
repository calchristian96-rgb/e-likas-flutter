import '../entities/family_registration_draft.dart';
import '../entities/pending_registration.dart';
import '../entities/pending_registration_status.dart';

class PendingQueueCounts {
  const PendingQueueCounts({
    required this.pending,
    required this.needsAttention,
  });

  final int pending;
  final int needsAttention;
}

/// CRUD + status transitions over the local pending-registration
/// queue — the encrypted staff Isar database is the only place any
/// of this data exists until a record is confirmed synced (201), at
/// which point its sensitive payload is deleted (see
/// `StaffSyncService`).
abstract class PendingQueueRepository {
  Future<List<PendingRegistrationSummary>> getAll();

  Future<PendingRegistrationDetail?> getDetail(String localId);

  /// Saves a brand-new registration as `pending`. Returns the
  /// generated `localId`.
  Future<String> enqueue(FamilyRegistrationDraft draft);

  /// Overwrites the draft of an existing record (used by the
  /// Review/Edit screen after a 422) and resets it to `pending` so
  /// it's picked up by the next sync run.
  Future<void> updateDraft(String localId, FamilyRegistrationDraft draft);

  Future<void> delete(String localId);

  Future<PendingQueueCounts> getCounts();

  // --- Used only by StaffSyncService — not by the UI directly. ---

  Future<void> markSyncing(String localId);

  Future<void> markSynced(String localId);

  Future<void> markNeedsAttention(
    String localId, {
    required PendingErrorCategory category,
    required String message,
    Map<String, List<String>>? fieldErrors,
  });

  /// Leaves the record `pending` (retryable later) after a transient
  /// failure (offline, 5xx) — distinct from [markNeedsAttention],
  /// which is for failures that need a human decision first.
  Future<void> markRetryLater(String localId, {required String message});

  /// Every record currently `pending`, in creation order — what a
  /// sync run processes, one at a time.
  Future<List<PendingRegistrationDetail>> getPendingQueueInOrder();
}
