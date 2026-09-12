import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/sync/sync_timestamps.dart';
import '../../domain/entities/alert.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../datasources/alerts_local_datasource.dart';
import '../datasources/alerts_remote_datasource.dart';

class AlertsRepositoryImpl implements AlertsRepository {
  AlertsRepositoryImpl({
    required AlertsRemoteDatasource remoteDatasource,
    required AlertsLocalDatasource localDatasource,
    required ConnectivityService connectivityService,
    required SyncTimestampService syncTimestampService,
  }) : _remote = remoteDatasource,
       _local = localDatasource,
       _connectivity = connectivityService,
       _syncTimestamps = syncTimestampService;

  final AlertsRemoteDatasource _remote;
  final AlertsLocalDatasource _local;
  final ConnectivityService _connectivity;
  final SyncTimestampService _syncTimestamps;

  @override
  Future<Result<AlertsFeed>> getAlerts({int limit = 20}) async {
    if (await _connectivity.hasConnection) {
      try {
        final page = await _remote.getAlerts(perPage: limit);
        await _local.cacheAlerts(page.alerts);
        await _syncTimestamps.markSynced(SyncDomain.alerts);
        return Success((
          alerts: page.alerts.map((m) => m.toEntity()).toList(),
          totalCount: page.totalCount,
        ));
      } catch (_) {
        // Network reported as available but the request still failed
        // — fall through to cache rather than surface an error the
        // resident can't do anything about. Same reasoning as
        // EvacuationCentersRepositoryImpl.
      }
    }

    final cached = await _local.getCachedAlerts();
    if (cached.isEmpty) {
      return const Failed(NetworkFailure('No alerts available offline yet.'));
    }

    // The cache is accumulative and can hold more than one page's worth,
    // so `limit` is applied here too — but `totalCount` reports
    // everything cached, not the truncated length. An offline count
    // that's lower than what the resident last saw online would read as
    // "alerts disappeared," which is exactly the wrong impression for
    // this app to give.
    return Success((
      alerts: cached.take(limit).map((m) => m.toEntity()).toList(),
      totalCount: cached.length,
    ));
  }

  @override
  Future<Result<Alert>> getAlertById(int id) async {
    // Cache-first here, the reverse of [getAlerts] — and deliberately.
    // The details screen is only reachable by tapping a row in the
    // list, and loading that list is exactly what wrote this alert to
    // the cache moments earlier. So the cached copy is already the same
    // data a network call would return, and going to the network first
    // would put a spinner (and, on a bad connection, a timeout) in
    // front of content the app is holding in its hand. There's also no
    // documented per-alert endpoint in the public API contract, so the
    // network path below has to re-fetch a whole page to find one
    // alert — worth doing as a fallback, not as the default.
    final cached = await _local.getCachedAlertById(id);
    if (cached != null) {
      return Success(cached.toEntity());
    }

    if (await _connectivity.hasConnection) {
      try {
        final page = await _remote.getAlerts(perPage: 50);
        await _local.cacheAlerts(page.alerts);
        for (final model in page.alerts) {
          if (model.id == id) return Success(model.toEntity());
        }
        // Reached the server fine, and this alert genuinely isn't in
        // the recent feed — most likely old enough to have fallen off
        // it. A distinct message from "couldn't load," because the
        // difference matters to whoever reports the problem.
        return const Failed(
          ServerFailure('That alert is no longer in the recent alerts feed.'),
        );
      } catch (_) {
        // fall through to the offline message below
      }
    }

    return const Failed(CacheFailure('That alert isn\'t available offline.'));
  }
}
