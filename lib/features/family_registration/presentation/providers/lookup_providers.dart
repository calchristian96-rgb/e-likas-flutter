import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/database/staff_database.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/staff_api_client.dart';
import '../../data/datasources/lookup_local_datasource.dart';
import '../../data/datasources/lookup_remote_datasource.dart';
import '../../data/repositories/lookup_repository_impl.dart';
import '../../data/services/lookup_sync_timestamps.dart';
import '../../domain/entities/lookup_entities.dart';
import '../../domain/repositories/lookup_repository.dart';
import '../../../staff_shell/current_event.dart';

part 'lookup_providers.g.dart';

@riverpod
LookupRepository lookupRepository(Ref ref) {
  return LookupRepositoryImpl(
    remote: LookupRemoteDataSource(ref.watch(staffApiClientProvider)),
    local: LookupLocalDataSource(ref.watch(staffDatabaseProvider)),
    connectivity: ref.watch(connectivityServiceProvider),
    syncTimestamps: ref.watch(lookupSyncTimestampServiceProvider),
  );
}

@riverpod
Future<List<Barangay>> barangays(Ref ref) async {
  final result = await ref.watch(lookupRepositoryProvider).getBarangays();
  return switch (result) {
    Success(:final value) => value,
    Failed(:final failure) => throw failure,
  };
}

@riverpod
Future<List<EvacuationEventLookup>> evacuationEventsLookup(Ref ref) async {
  final result = await ref
      .watch(lookupRepositoryProvider)
      .getEvacuationEvents();
  return switch (result) {
    Success(:final value) => value,
    Failed(:final failure) => throw failure,
  };
}

/// The staff center list for the selected event: its status and figures
/// are that event's (backend d17f6de), so it reloads when the event
/// changes.
@riverpod
Future<List<EvacuationCenterLookup>> evacuationCentersLookup(Ref ref) async {
  int? eventId;
  try {
    eventId = (await ref.watch(currentStaffEventProvider.future))?.id;
  } catch (_) {
    // No event known yet: the server uses the user's selected event.
  }
  final result = await ref
      .watch(lookupRepositoryProvider)
      .getEvacuationCenters(eventId: eventId);
  return switch (result) {
    Success(:final value) => value,
    Failed(:final failure) => throw failure,
  };
}
