import '../../../../core/error/result.dart';
import '../../../family_registration/domain/entities/pending_registration_status.dart';
import '../entities/ec_board_entry_draft.dart';
import '../entities/ec_board_quick_count.dart';
import '../entities/pending_ec_board_entry.dart';

class EcBoardQueueCounts {
  const EcBoardQueueCounts({
    required this.pending,
    required this.needsAttention,
  });

  final int pending;
  final int needsAttention;
}

/// CRUD + status transitions over the local Add Evacuee queue, mirroring
/// `PendingQueueRepository` exactly — same shape, one dataset smaller.
/// Plus the one live-only read this feature also needs: the quick-count
/// breakdown, which is never cached (see `getQuickCount`'s doc comment).
abstract class EcBoardRepository {
  Future<List<PendingEcBoardEntrySummary>> getAllForCenter(int centerId);

  Future<PendingEcBoardEntryDetail?> getDetail(String localId);

  /// Saves a brand-new entry as `pending`. Returns the generated
  /// `localId`.
  Future<String> enqueue(
    EcBoardEntryDraft draft, {
    required String householdLabel,
  });

  Future<void> updateDraft(
    String localId,
    EcBoardEntryDraft draft, {
    required String householdLabel,
  });

  Future<void> delete(String localId);

  Future<EcBoardQueueCounts> getCountsForCenter(int centerId);

  // --- Used only by StaffSyncService — not by the UI directly. ---

  Future<void> markSyncing(String localId);

  Future<void> markSynced(String localId);

  Future<void> markNeedsAttention(
    String localId, {
    required PendingErrorCategory category,
    required String message,
  });

  Future<void> markRetryLater(String localId, {required String message});

  /// Every record currently `pending`, in creation order, across every
  /// center — same "process everything, one flat queue" shape
  /// `PendingQueueRepository.getPendingQueueInOrder` uses.
  Future<List<PendingEcBoardEntryDetail>> getPendingQueueInOrder();

  /// Rewrites every pending entry whose [EcBoardEntryDraft
  /// .existingFamilyLocalId] matches [familyLocalId] to reference
  /// [remoteFamilyId] instead — the "promotion" step `StaffSyncService`
  /// runs immediately after a pending family registration syncs
  /// successfully, so an EC Board entry queued against a household
  /// that wasn't synced yet becomes syncable in the very same run.
  Future<void> promoteHouseholdReference({
    required String familyLocalId,
    required int remoteFamilyId,
  });

  /// One center+event's live breakdown — deliberately live-only, no
  /// offline cache, no bulk/reference-data refresh path: fetched only
  /// when a specific center's EC Board page is actually opened while
  /// online (see `ecBoardQuickCountProvider`). Returns [Failed] on any
  /// failure (offline, server error) — the UI shows that section as
  /// unavailable rather than a fabricated or stale count.
  Future<Result<EcBoardQuickCount>> getQuickCount({
    required int centerId,
    required int evacuationEventId,
  });

  /// The one online submission path:
  /// `POST /evacuation-centers/{id}/evacuees`. Returns the backend's
  /// `evacuee_id` (the response's top-level field — never `data.id`,
  /// which is the family's id, a real bug caught in the desktop app's
  /// equivalent work) on a confirmed 201.
  Future<Result<int>> submit(EcBoardEntryDraft draft);
}
