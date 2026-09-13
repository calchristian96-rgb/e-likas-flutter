import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/sync/sync_timestamps.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../domain/entities/center_facility.dart';
import '../../domain/entities/evacuation_center.dart';
import '../../domain/repositories/evacuation_centers_repository.dart';
import '../datasources/evacuation_centers_local_datasource.dart';
import '../datasources/evacuation_centers_remote_datasource.dart';
import '../models/evacuation_center_model.dart';

class EvacuationCentersRepositoryImpl implements EvacuationCentersRepository {
  EvacuationCentersRepositoryImpl({
    required EvacuationCentersRemoteDatasource remoteDatasource,
    required EvacuationCentersLocalDatasource localDatasource,
    required ConnectivityService connectivityService,
    required SyncTimestampService syncTimestampService,
  }) : _remote = remoteDatasource,
       _local = localDatasource,
       _connectivity = connectivityService,
       _syncTimestamps = syncTimestampService;

  final EvacuationCentersRemoteDatasource _remote;
  final EvacuationCentersLocalDatasource _local;
  final ConnectivityService _connectivity;
  final SyncTimestampService _syncTimestamps;

  @override
  Future<Result<List<EvacuationCenter>>> getAllCenters() async {
    if (await _connectivity.hasConnection) {
      try {
        final models = await _remote.getAllCenters();
        await _local.cacheCenters(models);
        await _syncTimestamps.markSynced(SyncDomain.evacuationCenters);
        return Success(models.map((m) => m.toEntity()).toList());
      } catch (_) {
        // Network reported as available but the request still failed
        // — fall through to cache rather than surface an error the
        // resident can't do anything about.
      }
    }
    final cached = await _local.getCachedCenters();
    if (cached.isEmpty) {
      return const Failed(NetworkFailure('No centers available offline yet.'));
    }
    return Success(cached.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Result<List<EvacuationCenter>>> getNearestCenters({
    required double latitude,
    required double longitude,
    int limit = 10,
    bool allowOfflineFallback = true,
  }) async {
    if (await _connectivity.hasConnection) {
      try {
        final models = await _remote.getNearestCenters(
          latitude: latitude,
          longitude: longitude,
          limit: limit,
        );
        await _local.cacheCenters(models);
        await _syncTimestamps.markSynced(SyncDomain.evacuationCenters);
        return Success(models.map((m) => m.toEntity()).toList());
      } catch (_) {
        // fall through to the offline ranking below
      }
    }

    if (!allowOfflineFallback) {
      return const Failed(NetworkFailure());
    }

    // Offline fallback: rank the last cached full list client-side —
    // same UX as the server's own nearest-center ranking, no new
    // endpoint involved. See the architecture notes on this.
    final cached = await _local.getCachedCenters();
    if (cached.isEmpty) {
      return const Failed(CacheFailure('No cached centers to rank yet.'));
    }

    // Centers with no coordinates can't be ranked by distance at all —
    // skipped here rather than assigned a fake `0`/fallback distance,
    // same rule as every other distance-dependent call site (see
    // `EvacuationCenter.hasCoordinates`'s doc comment). The server's
    // own `/nearest` endpoint excludes them too — confirmed against
    // `EvacuationCenter::nearestTo()`'s own explicit `WHERE latitude
    // IS NOT NULL AND longitude IS NOT NULL` guard — so this keeps the
    // offline fallback's behavior consistent with the online path.
    final withDistance =
        cached
            .map((m) => m.toEntity())
            .where((entity) => entity.hasCoordinates)
            .map((entity) {
              final meters = DistanceCalculator.metersBetween(
                lat1: latitude,
                lon1: longitude,
                lat2: entity.latitude!,
                lon2: entity.longitude!,
              );
              return entity.copyWithDistance(meters);
            })
            .toList()
          ..sort((a, b) => a.distanceMeters!.compareTo(b.distanceMeters!));

    return Success(withDistance.take(limit).toList());
  }

  /// Live-only, no cache/offline fallback — deliberately simpler than
  /// [getAllCenters]/[getNearestCenters]: this is new, independently-
  /// loading data (see the details page's Facilities section), not
  /// part of the existing Drift/Isar offline architecture. A failure
  /// here (including "no connection at all") surfaces as [Failed] and
  /// is handled entirely by that section, never the rest of the page.
  @override
  Future<Result<List<CenterFacility>>> getCenterFacilities(int centerId) async {
    try {
      final models = await _remote.getCenterFacilities(centerId);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (_) {
      return const Failed(NetworkFailure('Could not load facilities.'));
    }
  }

  /// See the interface doc comment for why this exists at all: the
  /// plain centers list never returns `photo_url`, so a center's
  /// cached row only ever gets a real photo via this backfill or a
  /// prior GIS map visit (`MapLocalDatasource.cacheMapData`, which
  /// already caches `photo_url` authoritatively for the exact same
  /// reason). Best-effort by design — a failure here must never turn
  /// into a visible error; the resident just keeps seeing the
  /// placeholder they were already seeing.
  @override
  Future<bool> refreshCenterPhotoIfMissing(int centerId) async {
    try {
      final cached = await _local.getCachedCenters();
      EvacuationCenterModel? existing;
      for (final c in cached) {
        if (c.id == centerId) {
          existing = c;
          break;
        }
      }
      // Nothing cached yet, or it already has a real photo — either
      // way there's nothing useful for this backfill to do.
      if (existing == null || existing.photoUrl != null) return false;
      if (!await _connectivity.hasConnection) return false;

      final photoUrl = await _remote.getCenterPhotoUrl(centerId);
      if (photoUrl == null || photoUrl.isEmpty) return false;

      await _local.updatePhotoUrl(centerId, photoUrl);
      return true;
    } catch (_) {
      return false;
    }
  }
}
