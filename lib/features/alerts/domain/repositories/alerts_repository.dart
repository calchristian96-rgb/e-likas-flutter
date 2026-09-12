import '../../../../core/error/result.dart';
import '../entities/alert.dart';

/// One alerts fetch, as the domain layer sees it: the alerts themselves
/// plus the total the backend reports.
///
/// [totalCount] is kept separate from `alerts.length` because they
/// legitimately differ — the app only ever requests the most recent
/// page, while the count drives the Home Dashboard's "public alerts"
/// statistic, which means *all* of them. When the answer comes from
/// cache there's no server total to report, so it falls back to the
/// cached length; see [AlertsRepositoryImpl] for that path.
typedef AlertsFeed = ({List<Alert> alerts, int totalCount});

/// Contract the data layer implements. Domain and presentation depend
/// on this abstraction only — never on Dio or Isar directly.
abstract class AlertsRepository {
  /// Recent public alerts, newest first, network-first with cache
  /// fallback.
  Future<Result<AlertsFeed>> getAlerts({int limit = 20});

  /// A single alert by its backend id.
  ///
  /// Cache-first, unlike [getAlerts] — see the implementation for why
  /// the details screen inverts the usual order.
  Future<Result<Alert>> getAlertById(int id);
}
