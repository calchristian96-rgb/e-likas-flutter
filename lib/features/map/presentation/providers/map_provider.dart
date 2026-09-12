import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/database/resident_database.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/sync/sync_timestamps.dart';
import '../../data/datasources/map_local_datasource.dart';
import '../../data/datasources/map_remote_datasource.dart';
import '../../data/repositories/map_repository_impl.dart';
import '../../domain/entities/map_data.dart';
import '../../domain/repositories/map_repository.dart';
import '../../domain/usecases/get_map_data.dart';

part 'map_provider.g.dart';

@riverpod
MapRepository mapRepository(Ref ref) {
  return MapRepositoryImpl(
    remoteDatasource: MapRemoteDatasource(ref.watch(apiClientProvider)),
    localDatasource: MapLocalDatasource(ref.watch(residentDatabaseProvider)),
    connectivityService: ref.watch(connectivityServiceProvider),
    syncTimestampService: ref.watch(syncTimestampServiceProvider),
  );
}

/// Drives the hazard map screen.
@riverpod
Future<MapData> mapData(Ref ref) async {
  final repository = ref.watch(mapRepositoryProvider);
  final result = await GetMapData(repository).call();
  return switch (result) {
    Success(:final value) => value,
    Failed(:final failure) => throw failure,
  };
}
