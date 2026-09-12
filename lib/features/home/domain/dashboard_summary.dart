import '../../alerts/domain/entities/alert.dart';

/// How fresh the data currently shown actually is. Derived honestly
/// from connectivity + whether the underlying data loaded — not
/// tracked precisely per-source (the existing repositories don't
/// currently expose "this came from cache vs network" as metadata,
/// and adding that would mean changing stable, working repository
/// code for a Home-dashboard-only need).
///
/// - [live]: connected, and data loaded — very likely fresh, though a
///   repository could theoretically still have silently served cache
///   while online if a request failed for an unrelated reason.
/// - [cached]: not connected, but data loaded anyway — must have come
///   from Isar, since there's no network to have served it live.
/// - [offline]: not connected, and nothing has loaded yet.
/// - [unavailable]: connected, but the fetch still failed — a real
///   backend/data problem, not just a connectivity one.
enum DataFreshness { live, cached, offline, unavailable }

class DashboardSummary {
  const DashboardSummary({
    required this.totalCenters,
    required this.alertCount,
    required this.latestAlert,
    required this.isConnected,
    required this.freshness,
  });

  final int totalCenters;
  final int alertCount;
  final Alert? latestAlert;
  final bool isConnected;
  final DataFreshness freshness;
}
