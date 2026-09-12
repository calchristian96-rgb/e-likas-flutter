import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/sync/sync_timestamps.dart';
import '../../domain/entities/map_data.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/map_local_datasource.dart';
import '../datasources/map_remote_datasource.dart';

class MapRepositoryImpl implements MapRepository {
  MapRepositoryImpl({
    required MapRemoteDatasource remoteDatasource,
    required MapLocalDatasource localDatasource,
    required ConnectivityService connectivityService,
    required SyncTimestampService syncTimestampService,
  }) : _remote = remoteDatasource,
       _local = localDatasource,
       _connectivity = connectivityService,
       _syncTimestamps = syncTimestampService;

  final MapRemoteDatasource _remote;
  final MapLocalDatasource _local;
  final ConnectivityService _connectivity;
  final SyncTimestampService _syncTimestamps;

  @override
  Future<Result<MapData>> getMapData() async {
    if (await _connectivity.hasConnection) {
      try {
        final fetched = await _remote.getMapData();
        await _local.cacheMapData(fetched.centers, fetched.hazardAreas);
        await _syncTimestamps.markSynced(SyncDomain.hazardMap);
        return Success(
          MapData(
            centers: fetched.centers.map((m) => m.toEntity()).toList(),
            hazardAreas: fetched.hazardAreas.map((m) => m.toEntity()).toList(),
          ),
        );
      } catch (_) {
        // Network reported as available but the request still failed
        // — fall through to cache, same reasoning as evacuation_centers.
      }
    }

    final cached = await _local.getCachedMapData();
    if (cached.centers.isEmpty && cached.hazardAreas.isEmpty) {
      return const Failed(NetworkFailure('No map data available offline yet.'));
    }
    return Success(
      MapData(
        centers: cached.centers.map((m) => m.toEntity()).toList(),
        hazardAreas: cached.hazardAreas.map((m) => m.toEntity()).toList(),
      ),
    );
  }
}
