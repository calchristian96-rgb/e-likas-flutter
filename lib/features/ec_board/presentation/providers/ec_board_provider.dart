import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/staff_database.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/staff_api_client.dart';
import '../../../staff_auth/presentation/providers/staff_auth_provider.dart';
import '../../data/datasources/ec_board_local_datasource.dart';
import '../../data/datasources/ec_board_remote_datasource.dart';
import '../../data/repositories/ec_board_repository_impl.dart';
import '../../domain/entities/ec_board_entry_draft.dart';
import '../../domain/entities/ec_board_quick_count.dart';
import '../../domain/entities/pending_ec_board_entry.dart';
import '../../domain/entities/pending_quick_count_edit.dart';
import '../../domain/entities/quick_departure_request.dart';
import '../../domain/entities/sectoral_group_draft.dart';
import '../../domain/repositories/ec_board_repository.dart';

part 'ec_board_provider.g.dart';

/// Rebuilds — and re-scopes every provider below it — whenever the
/// signed-in staff account changes, same pattern as
/// `pendingQueueRepositoryProvider`.
@riverpod
EcBoardRepository ecBoardRepository(Ref ref) {
  final session = ref.watch(staffAuthProvider).value;
  return EcBoardRepositoryImpl(
    EcBoardLocalDataSource(ref.watch(staffDatabaseProvider)),
    EcBoardRemoteDataSource(ref.watch(staffApiClientProvider)),
    ownerStaffId: session?.id,
  );
}

@riverpod
Future<List<PendingEcBoardEntrySummary>> ecBoardEntriesForCenter(
  Ref ref,
  int centerId,
) {
  return ref.watch(ecBoardRepositoryProvider).getAllForCenter(centerId);
}

@riverpod
Future<PendingEcBoardEntryDetail?> ecBoardEntryDetail(Ref ref, String localId) {
  return ref.watch(ecBoardRepositoryProvider).getDetail(localId);
}

@riverpod
Future<EcBoardQueueCounts> ecBoardCountsForCenter(Ref ref, int centerId) {
  return ref.watch(ecBoardRepositoryProvider).getCountsForCenter(centerId);
}

/// The live "last known" breakdown — deliberately fetched only when
/// this exact provider is watched (i.e. only when a specific center's
/// EC Board page is actually open), never as part of any general
/// reference-data/lookup refresh. `.autoDispose` (the default for a
/// plain `@riverpod` function) means leaving the page tears this
/// down — reopening re-fetches fresh rather than showing a
/// silently-aging snapshot.
@riverpod
Future<EcBoardQuickCount> ecBoardQuickCount(
  Ref ref,
  int centerId,
  int evacuationEventId,
) async {
  final result = await ref
      .watch(ecBoardRepositoryProvider)
      .getQuickCount(centerId: centerId, evacuationEventId: evacuationEventId);
  return switch (result) {
    Success(:final value) => value,
    Failed(:final failure) => throw failure,
  };
}

/// The single online-submit path (`POST /evacuation-centers/{id}
/// /evacuees`), shared by the Add Evacuee form's "try online first"
/// branch and `StaffSyncService` — same one-wiring-not-two convention
/// `registrationSubmitProvider` already established.
@riverpod
Future<Result<int>> Function(EcBoardEntryDraft draft) ecBoardSubmit(Ref ref) {
  final repository = ref.watch(ecBoardRepositoryProvider);
  return (draft) => repository.submit(draft);
}

/// This device's own not-yet-synced sectoral/4Ps edit for one
/// center+event, or null when there isn't one — watched by both the
/// edit form (to resume an unsynced draft) and `EcBoardPage` (to show
/// the "Pending" card). `.autoDispose`, same reasoning as
/// [ecBoardQuickCount]: re-fetches fresh from local storage every time
/// the page reopens rather than risking a stale in-memory copy after a
/// sync run elsewhere invalidates it.
@riverpod
Future<PendingQuickCountEditDetail?> pendingQuickCountEdit(
  Ref ref,
  int centerId,
  int evacuationEventId,
) {
  return ref
      .watch(ecBoardRepositoryProvider)
      .getPendingQuickCountEdit(
        centerId: centerId,
        evacuationEventId: evacuationEventId,
      );
}

/// The single online-submit path (`PUT /evacuation-centers/{id}
/// /quick-count`) — shared by the sectoral/4Ps edit form's "try online
/// first" branch and `StaffSyncService`, same one-wiring-not-two
/// convention as [ecBoardSubmit].
@riverpod
Future<Result<EcBoardQuickCount>> Function(SectoralGroupDraft draft)
ecBoardUpdateQuickCount(Ref ref) {
  final repository = ref.watch(ecBoardRepositoryProvider);
  return (draft) => repository.updateQuickCount(draft);
}

/// The single Quick Departure submission path (`POST
/// /evacuation-centers/{id}/quick-departure`) — **online-only, never
/// queued**, so unlike [ecBoardSubmit]/[ecBoardUpdateQuickCount] there
/// is no offline fallback branch for a caller to reach for; the form
/// itself must confirm connectivity before ever calling this (see
/// `QuickDepartureRequest`'s doc comment for why).
@riverpod
Future<Result<String>> Function(QuickDepartureRequest request)
ecBoardQuickDeparture(Ref ref) {
  final repository = ref.watch(ecBoardRepositoryProvider);
  return (request) => repository.quickDeparture(request);
}
