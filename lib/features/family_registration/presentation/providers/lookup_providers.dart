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

@riverpod
Future<List<EvacuationCenterLookup>> evacuationCentersLookup(Ref ref) async {
  final result = await ref
      .watch(lookupRepositoryProvider)
      .getEvacuationCenters();
  return switch (result) {
    Success(:final value) => value,
    Failed(:final failure) => throw failure,
  };
}
