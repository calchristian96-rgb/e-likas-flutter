import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/database/staff_database.dart';
import '../../../core/network/staff_api_client.dart';
import '../../family_registration/presentation/providers/lookup_providers.dart';
import '../../family_registration/presentation/providers/pending_queue_provider.dart';
import '../../home/presentation/providers/home_provider.dart';
import '../../staff_auth/presentation/providers/staff_auth_provider.dart';
import '../data/outbox_repository.dart';
import '../domain/pending_action.dart';

/// Scoped to the signed-in account (`ownerStaffId`), like every other
/// staff queue.
final outboxRepositoryProvider = Provider<OutboxRepository>((ref) {
  return OutboxRepository(
    ref.watch(staffDatabaseProvider),
    ref.watch(staffApiClientProvider),
    ref.watch(connectivityServiceProvider),
    ref.watch(staffAuthProvider).value?.id,
  );
});

/// Bumped after every enqueue and every sync run. Staff data providers
/// watch it, so a screen refetches once its queued actions reached the
/// server, and shows "waiting to sync" rows in the meantime.
class OutboxRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final outboxRevisionProvider = NotifierProvider<OutboxRevision, int>(
  OutboxRevision.new,
);

final pendingActionsProvider = FutureProvider<List<PendingAction>>((ref) {
  ref.watch(outboxRevisionProvider);
  return ref.watch(outboxRepositoryProvider).getAll();
});

/// Everything this device still has to send, as one summary.
class SyncSummary {
  const SyncSummary({required this.waiting, required this.needAttention});

  final int waiting;
  final int needAttention;

  bool get isEmpty => waiting == 0 && needAttention == 0;
}

final syncSummaryProvider = FutureProvider<SyncSummary>((ref) async {
  final actions = await ref.watch(pendingActionsProvider.future);
  final registrations = await ref.watch(pendingQueueCountsProvider.future);
  return SyncSummary(
    waiting:
        actions.where((a) => !a.needsAttention).length + registrations.pending,
    needAttention:
        actions.where((a) => a.needsAttention).length +
        registrations.needsAttention,
  );
});

/// One sync for everything, in order: families and EC Board entries
/// first (an action may refer to a family that was only on this device),
/// then the action queue. Kept alive so a run started from a screen that
/// closes still finishes and refreshes.
class StaffSyncAll {
  StaffSyncAll(this._ref);

  final Ref _ref;
  Future<OutboxRunResult>? _inFlight;

  Future<OutboxRunResult> call() => _inFlight ??= _run().whenComplete(() {
    _inFlight = null;
  });

  Future<OutboxRunResult> _run() async {
    if (_ref.read(staffAuthProvider).value == null) {
      return const OutboxRunResult();
    }
    final families = await _ref.read(staffSyncNowProvider)();
    if (families.stoppedForAuth) {
      return const OutboxRunResult(stoppedForAuth: true);
    }
    final result = await _ref.read(outboxRepositoryProvider).run();
    _ref.read(outboxRevisionProvider.notifier).bump();
    // The first check-in switches an event in monitoring to active on
    // the server (backend EventFlow): read the events again.
    if (families.processed > 0 || result.sent > 0) {
      _ref.invalidate(evacuationEventsLookupProvider);
    }
    return OutboxRunResult(
      sent: result.sent + families.processed,
      needAttention: result.needAttention,
      stoppedForAuth: result.stoppedForAuth,
      wasOffline: result.wasOffline || families.wasOffline,
    );
  }
}

final staffSyncAllProvider = Provider<StaffSyncAll>(StaffSyncAll.new);

/// Queue one field action, then try to send it right away when online.
Future<PendingAction> enqueueStaffAction(
  WidgetRef ref, {
  required PendingActionKind kind,
  required String method,
  required String path,
  required Map<String, dynamic> body,
  required String summary,
  String? subjectKey,
}) async {
  final action = await ref
      .read(outboxRepositoryProvider)
      .enqueue(
        kind: kind,
        method: method,
        path: path,
        body: body,
        summary: summary,
        subjectKey: subjectKey,
      );
  ref.read(outboxRevisionProvider.notifier).bump();
  // Fire and forget: the queue keeps the action if this fails.
  ref.read(staffSyncAllProvider)();
  return action;
}

/// Syncs Staff Mode by itself: when it opens, when the connection comes
/// back, and when the app returns to the foreground. Sync Now stays for
/// an explicit try.
class StaffAutoSync extends ConsumerStatefulWidget {
  const StaffAutoSync({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StaffAutoSync> createState() => _StaffAutoSyncState();
}

class _StaffAutoSyncState extends ConsumerState<StaffAutoSync>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  void _sync() {
    if (!mounted) return;
    ref.read(staffSyncAllProvider)();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(connectivityStatusProvider, (previous, next) {
      if (previous?.value == false && next.value == true) _sync();
    });
    return widget.child;
  }
}
