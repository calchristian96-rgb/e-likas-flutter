import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/database/staff_database.dart';
import '../../../core/error/result.dart';
import '../../../core/network/staff_api_client.dart';
import '../../family_registration/presentation/providers/pending_queue_provider.dart';
import '../../staff_auth/presentation/providers/staff_auth_provider.dart';
import '../../staff_shell/current_event.dart';
import '../data/sent_family_api.dart';
import '../data/sent_history_repository.dart';
import '../domain/sent_family.dart';
import '../domain/sent_record.dart';
import 'outbox_providers.dart';

/// The Sync page, opened on its Sent tab.
const sentListLocation = '/staff/more/sync?tab=sent';

/// Scoped to the signed-in account, like every staff queue.
final sentHistoryRepositoryProvider = Provider<SentHistoryRepository>((ref) {
  return SentHistoryRepository(
    ref.watch(staffDatabaseProvider),
    ref.watch(staffAuthProvider).value?.id,
  );
});

/// What this phone sent for the selected event, newest first (at most
/// 200 rows, 14 days). Refreshed after every sync.
final sentRecordsProvider = FutureProvider.autoDispose<List<SentRecord>>((
  ref,
) async {
  ref.watch(outboxRevisionProvider);
  // Registrations synced from their own screen invalidate this one.
  ref.watch(pendingQueueCountsProvider);
  int? eventId;
  try {
    eventId = (await ref.watch(currentStaffEventProvider.future))?.id;
  } catch (_) {
    // No event known: every row.
  }
  return ref.watch(sentHistoryRepositoryProvider).list(eventId: eventId);
});

final sentFamilyApiProvider = Provider<SentFamilyApi>(
  (ref) => SentFamilyApi(
    ref.watch(staffApiClientProvider),
    ref.watch(connectivityServiceProvider),
  ),
);

/// A sent family as the server has it now (online only).
final sentFamilyProvider = FutureProvider.autoDispose.family<SentFamily, int>((
  ref,
  id,
) async {
  final result = await ref.watch(sentFamilyApiProvider).getFamily(id);
  return switch (result) {
    Success(:final value) => value,
    Failed(:final failure) => throw failure,
  };
});

/// One automatic send that delivered something, for the snackbar.
class AutoSent {
  const AutoSent(this.count, this.at);

  final int count;
  final DateTime at;
}

class AutoSentNotifier extends Notifier<AutoSent?> {
  @override
  AutoSent? build() => null;

  /// A new value each time, so two sends of the same size both show.
  void announce(int count) => state = AutoSent(count, DateTime.now());
}

final autoSentProvider = NotifierProvider<AutoSentNotifier, AutoSent?>(
  AutoSentNotifier.new,
);
