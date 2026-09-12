import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/lookup_entities.dart';
import '../../domain/repositories/lookup_repository.dart';
import '../datasources/lookup_local_datasource.dart';
import '../datasources/lookup_remote_datasource.dart';
import '../services/lookup_sync_timestamps.dart';

/// Network-first with cache fallback, same shape as
/// `AlertsRepositoryImpl` — just against the staff Isar cache and the
/// authenticated lookup endpoints instead of the resident ones.
class LookupRepositoryImpl implements LookupRepository {
  LookupRepositoryImpl({
    required LookupRemoteDataSource remote,
    required LookupLocalDataSource local,
    required ConnectivityService connectivity,
    required LookupSyncTimestampService syncTimestamps,
  }) : _remote = remote,
       _local = local,
       _connectivity = connectivity,
       _syncTimestamps = syncTimestamps;

  final LookupRemoteDataSource _remote;
  final LookupLocalDataSource _local;
  final ConnectivityService _connectivity;
  final LookupSyncTimestampService _syncTimestamps;

  @override
  Future<Result<List<Barangay>>> getBarangays() async {
    if (await _connectivity.hasConnection) {
      try {
        final models = await _remote.getBarangays();
        await _local.cacheBarangays(models);
        await _syncTimestamps.markSynced(LookupDomain.barangays);
        return Success(
          models.map((m) => Barangay(id: m.id, name: m.name)).toList(),
        );
      } catch (_) {
        // fall through to cache
      }
    }
    final cached = await _local.getCachedBarangays();
    if (cached.isEmpty) {
      return const Failed(
        NetworkFailure('No saved barangay list available offline yet.'),
      );
    }
    return Success(
      cached.map((m) => Barangay(id: m.id, name: m.name)).toList(),
    );
  }

  @override
  Future<Result<List<EvacuationEventLookup>>> getEvacuationEvents() async {
    if (await _connectivity.hasConnection) {
      try {
        final models = await _remote.getEvacuationEvents();
        await _local.cacheEvacuationEvents(models);
        await _syncTimestamps.markSynced(LookupDomain.evacuationEvents);
        return Success(models.map(_eventToEntity).toList());
      } catch (_) {
        // fall through to cache
      }
    }
    final cached = await _local.getCachedEvacuationEvents();
    if (cached.isEmpty) {
      return const Failed(
        NetworkFailure('No saved evacuation events available offline yet.'),
      );
    }
    return Success(cached.map(_eventToEntity).toList());
  }

  @override
  Future<Result<List<EvacuationCenterLookup>>> getEvacuationCenters() async {
    if (await _connectivity.hasConnection) {
      try {
        final models = await _remote.getEvacuationCenters();
        await _local.cacheEvacuationCenters(models);
        await _syncTimestamps.markSynced(LookupDomain.evacuationCenters);
        return Success(models.map(_centerToEntity).toList());
      } catch (_) {
        // fall through to cache
      }
    }
    final cached = await _local.getCachedEvacuationCenters();
    if (cached.isEmpty) {
      return const Failed(
        NetworkFailure('No saved evacuation centers available offline yet.'),
      );
    }
    return Success(cached.map(_centerToEntity).toList());
  }

  @override
  Future<int?> lastSyncedAt(LookupDomain domain) =>
      _syncTimestamps.getSyncedEpochMs(domain);

  EvacuationEventLookup _eventToEntity(dynamic m) => EvacuationEventLookup(
    id: m.id as int,
    name: m.name as String,
    status: m.status as String,
    startDate: m.startDate as String?,
    endDate: m.endDate as String?,
  );

  EvacuationCenterLookup _centerToEntity(dynamic m) => EvacuationCenterLookup(
    id: m.id as int,
    name: m.name as String,
    barangayId: m.barangayId as int,
    status: m.status as String,
  );
}
