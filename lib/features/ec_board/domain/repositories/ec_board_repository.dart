import '../../../../core/error/result.dart';
import '../../../family_registration/domain/entities/pending_registration_status.dart';
import '../entities/ec_board_entry_draft.dart';
import '../entities/ec_board_quick_count.dart';
import '../entities/family_here.dart';
import '../entities/pending_ec_board_entry.dart';
import '../entities/quick_departure_request.dart';

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

  /// This device's own still-pending [HouseholdMode.new_] entries for
  /// one center+event — each one a genuinely distinct household this
  /// staff account created inline via Add Evacuee (never merged with
  /// [getAllForCenter]'s full list, which includes every household
  /// mode and every event). Surfaced by the household picker
  /// alongside synced and pending-family-registration households, so
  /// a second evacuee can join one of *these* before it's ever synced
  /// — see [EcBoardSubmitResult]'s doc comment for how that reference
  /// gets promoted to a real family id once this entry itself syncs.
  Future<List<PendingEcBoardEntrySummary>> getPendingNewHouseholds({
    required int centerId,
    required int evacuationEventId,
  });

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
  /// [remoteFamilyId] instead. [familyLocalId] can be either a
  /// `PendingFamilyRegistrations.localId` (the "promotion" step
  /// `StaffSyncService` runs immediately after a pending family
  /// registration syncs) or another `PendingEcBoardEntries.localId`
  /// whose own [HouseholdMode.new_] submission just created that
  /// family (see [EcBoardSubmitResult]'s doc comment) — either way, an
  /// EC Board entry queued against a household that wasn't synced yet
  /// becomes syncable in the very same run.
  Future<void> promoteHouseholdReference({
    required String familyLocalId,
    required int remoteFamilyId,
  });

  /// The families here right now (see [FamilyHere]) -- live only, never
  /// cached: whether a family is still here changes with every arrival
  /// and departure.
  Future<Result<List<FamilyHere>>> getFamiliesHere({
    required int centerId,
    required int evacuationEventId,
  });

  /// One center+event's live breakdown. Network-first: a successful
  /// fetch is also cached locally, so a failure (offline, server
  /// error) falls back to the last cached snapshot — marked
  /// [EcBoardQuickCount.isFromCache] — instead of [Failed], the same
  /// "still show *something* real, clearly labeled" pattern every
  /// other lookup in this app uses. Only genuinely [Failed] when
  /// nothing has ever been cached for this center+event yet.
  Future<Result<EcBoardQuickCount>> getQuickCount({
    required int centerId,
    required int evacuationEventId,
  });

  /// The one online submission path:
  /// `POST /evacuation-centers/{id}/evacuees`. See
  /// [EcBoardSubmitResult]'s doc comment for why both ids it carries
  /// matter, not just the evacuee's.
  Future<Result<EcBoardSubmitResult>> submit(EcBoardEntryDraft draft);

  /// `POST /evacuation-centers/{id}/quick-departure` —
  /// **deliberately never queued offline**; see
  /// [QuickDepartureRequest]'s doc comment for why. Callers must check
  /// connectivity themselves before ever presenting this action, same
  /// as the UI-level guard already does. Returns the backend's own
  /// confirmation message (e.g. "3 evacuee(s) marked as departed.")
  /// on success.
  Future<Result<String>> quickDeparture(QuickDepartureRequest request);
}
