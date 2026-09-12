import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/database/resident_database.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/sync/sync_timestamps.dart';
import '../../data/datasources/alerts_local_datasource.dart';
import '../../data/datasources/alerts_remote_datasource.dart';
import '../../data/repositories/alerts_repository_impl.dart';
import '../../domain/entities/alert.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../../domain/usecases/get_alert_by_id.dart';
import '../../domain/usecases/get_alerts.dart';

part 'alerts_summary_provider.g.dart';

/// Assembled exactly like [evacuationCentersRepositoryProvider] — same
/// collaborators, all resolved from the existing shared core providers
/// rather than constructed here.
@riverpod
AlertsRepository alertsRepository(Ref ref) {
  return AlertsRepositoryImpl(
    remoteDatasource: AlertsRemoteDatasource(ref.watch(apiClientProvider)),
    localDatasource: AlertsLocalDatasource(ref.watch(residentDatabaseProvider)),
    connectivityService: ref.watch(connectivityServiceProvider),
    syncTimestampService: ref.watch(syncTimestampServiceProvider),
  );
}

/// Latest alert + total count for the Home Dashboard.
///
/// Now goes through [AlertsRepository] rather than calling the remote
/// datasource directly, which is what gives the dashboard the same
/// offline-first behaviour the rest of the app has — a resident opening
/// the app with no connection now sees the last alert they received
/// instead of an error card. The failure it throws is still a
/// [Failure], as before, so `home_page.dart`'s `.message` extraction
/// keeps working untouched.
@riverpod
Future<({Alert? latest, int count})> alertsSummary(Ref ref) async {
  final repository = ref.watch(alertsRepositoryProvider);
  // A handful of the most recent alerts, not the whole history — the
  // dashboard only ever shows the single newest one.
  final result = await GetAlerts(repository).call(limit: 5);
  return switch (result) {
    Success(:final value) => (
      latest: value.alerts.isNotEmpty ? value.alerts.first : null,
      count: value.totalCount,
    ),
    Failed(:final failure) => throw failure,
  };
}

/// The full alerts list for the Alerts tab.
///
/// Deliberately still its own provider rather than being derived from
/// [alertsSummary]: `home_page.dart` and `alerts_page.dart` each call
/// `ref.invalidate` on their own provider to drive pull-to-refresh, and
/// a derived provider wouldn't refetch when invalidated. Two providers
/// that each own their fetch keeps every existing refresh call site
/// working exactly as it did.
@riverpod
Future<List<Alert>> alertsList(Ref ref) async {
  final repository = ref.watch(alertsRepositoryProvider);
  final result = await GetAlerts(repository).call(limit: 20);
  return switch (result) {
    Success(:final value) => value.alerts,
    Failed(:final failure) => throw failure,
  };
}

/// A single alert for the details screen.
///
/// Positional family parameter rather than a named one, matching
/// [nearestEvacuationCenters] — the same conservatively-supported
/// riverpod_generator pattern this project settled on.
@riverpod
Future<Alert> alertById(Ref ref, int id) async {
  final repository = ref.watch(alertsRepositoryProvider);
  final result = await GetAlertById(repository).call(id);
  return switch (result) {
    Success(:final value) => value,
    Failed(:final failure) => throw failure,
  };
}
