import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/database/staff_database.dart';
import '../../../../core/debug/pending_count_debug_log.dart';
import '../../../ec_board/presentation/providers/ec_board_provider.dart';
import '../../../registered_families/presentation/providers/registered_families_provider.dart';
import '../../../staff_auth/presentation/providers/staff_auth_provider.dart';
import '../../data/datasources/pending_queue_local_datasource.dart';
import '../../data/repositories/pending_queue_repository_impl.dart';
import '../../data/services/staff_sync_service.dart';
import '../../domain/entities/pending_registration.dart';
import '../../domain/repositories/pending_queue_repository.dart';
import 'lookup_providers.dart';
import 'registration_submit_provider.dart';

part 'pending_queue_provider.g.dart';

/// Rebuilds — and so re-scopes every provider below it — whenever the
/// signed-in staff account changes (login, logout, or a different
/// account signing in), by watching [staffAuthProvider] for the
/// current session's real backend user id. See
/// [PendingQueueRepositoryImpl]'s doc comment for why that id, not
/// name/email, is the ownership key.
@riverpod
PendingQueueRepository pendingQueueRepository(Ref ref) {
  final session = ref.watch(staffAuthProvider).value;
  final ownerStaffId = session?.id;
  pendingCountDebugLog(
    'B session resolved staffId=$ownerStaffId role=${session?.role}',
  );
  return PendingQueueRepositoryImpl(
    PendingQueueLocalDataSource(ref.watch(staffDatabaseProvider)),
    ref.watch(lookupRepositoryProvider),
    ownerStaffId: ownerStaffId,
  );
}

@riverpod
StaffSyncService staffSyncService(Ref ref) {
  return StaffSyncService(
    pendingQueueRepository: ref.watch(pendingQueueRepositoryProvider),
    registrationRepository: ref.watch(registrationSubmitProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    ecBoardRepository: ref.watch(ecBoardRepositoryProvider),
  );
}

@riverpod
Future<List<PendingRegistrationSummary>> pendingRegistrations(Ref ref) {
  return ref.watch(pendingQueueRepositoryProvider).getAll();
}

@riverpod
Future<PendingQueueCounts> pendingQueueCounts(Ref ref) async {
  pendingCountDebugLog('A UI provider requested');
  try {
    final counts = await ref.watch(pendingQueueRepositoryProvider).getCounts();
    pendingCountDebugLog(
      'provider success pending=${counts.pending} '
      'needsAttention=${counts.needsAttention}',
    );
    return counts;
  } catch (error, stackTrace) {
    pendingCountDebugLog('provider ERROR TYPE=${error.runtimeType}');
    pendingCountDebugLog('provider ERROR=$error');
    pendingCountDebugLog('provider STACK=$stackTrace');
    rethrow;
  }
}

@riverpod
Future<PendingRegistrationDetail?> pendingRegistrationDetail(
  Ref ref,
  String localId,
) {
  return ref.watch(pendingQueueRepositoryProvider).getDetail(localId);
}

/// A callable rather than a plain async method, so both the Staff
/// Workspace's "Sync Now" button and the Pending Registrations
/// screen's own sync action can trigger the same run and have it
/// automatically refresh every provider that reads the queue,
/// without either screen needing to know which providers those are.
///
/// `keepAlive: true` is load-bearing, not cosmetic: every caller
/// reaches this via a one-shot `ref.read(staffSyncNowProvider)()`,
/// never `ref.watch`, so nothing keeps a plain autoDispose instance of
/// this alive while the returned closure is still mid-flight — with
/// three sequential network phases (family queue, EC Board queue,
/// sectoral/4Ps queue) now chained through `service.run()`, that flight
/// is long enough that Riverpod could dispose this provider (and the
/// `ref` the closure already closed over) before the closure reaches
/// its own `ref.invalidate(...)` calls, throwing "Cannot use the Ref
/// of staffSyncNowProvider after it has been disposed" — confirmed
/// live: the sync's own PUT/POST calls still completed and saved
/// correctly, but the post-sync UI refresh crashed before ever
/// running.
@Riverpod(keepAlive: true)
Future<StaffSyncRunResult> Function() staffSyncNow(Ref ref) {
  return () async {
    final service = ref.read(staffSyncServiceProvider);
    final result = await service.run();

    ref.invalidate(pendingQueueCountsProvider);
    ref.invalidate(pendingRegistrationsProvider);

    // Every EC Board provider family, for every center currently on
    // screen — `run()` always processes the EC Board queue too (see
    // `StaffSyncService`), so a Sync Now triggered from either this
    // screen or `EcBoardPage` itself must refresh both.
    ref.invalidate(ecBoardEntriesForCenterProvider);
    ref.invalidate(ecBoardCountsForCenterProvider);
    ref.invalidate(ecBoardQuickCountProvider);
    ref.invalidate(pendingQuickCountEditProvider);

    // A registration that just synced here may now be a choosable
    // "existing household" on EC Board's Add Evacuee picker — refresh
    // the registered-families cache too, not just the queue itself, so
    // staff see it without a separate trip to Registered Families.
    if (result.processed > 0) {
      ref.invalidate(registeredFamiliesProvider);
      ref.invalidate(registeredFamiliesCacheOnlyProvider);
    }

    if (result.stoppedForAuth) {
      // Re-runs staffAuthProvider's restoreSession(), which will get
      // the same 401 and correctly clear the now-invalid token —
      // no separate "force logout" path to keep in sync with that
      // one.
      ref.invalidate(staffAuthProvider);
    }

    return result;
  };
}
