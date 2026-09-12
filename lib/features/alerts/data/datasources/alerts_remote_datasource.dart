import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/alert_model.dart';

/// Result of one alerts fetch: the parsed alerts (assumed newest-first,
/// matching standard alert/notification feed convention) and a total
/// count for the "public alert count" statistic.
///
/// Now carries [AlertModel]s rather than `Alert` entities — the change
/// the caching layer required, and the same data-layer/domain-layer
/// split evacuation_centers and map already use: datasources return
/// models, the repository maps them to entities. The Home Dashboard's
/// minimal slice returned entities straight from here only because it
/// had no repository at all yet.
typedef AlertsPage = ({List<AlertModel> alerts, int totalCount});

class AlertsRemoteDatasource {
  const AlertsRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<AlertsPage> getAlerts({int? perPage}) async {
    final response = await _apiClient.get(
      ApiEndpoints.alerts,
      queryParameters: perPage != null ? {'per_page': perPage} : null,
    );
    // Reuses the same ApiResponse<T> wrapper the other two datasources
    // use for the outer {success, message, data} envelope, rather than
    // reading response.data['data'] directly.
    final parsed = ApiResponse<AlertsPage>.fromJson(
      response.data as Map<String, dynamic>,
      _parseAlertsPage,
    );
    return parsed.data;
  }

  /// The outer envelope is handled by [ApiResponse.fromJson] above —
  /// this only handles what's specific to this endpoint: the exact
  /// shape of pagination inside `data` isn't confirmed yet, so it's
  /// handled defensively for the two most likely shapes rather than
  /// assuming one.
  AlertsPage _parseAlertsPage(dynamic rawData) {
    final List<dynamic> items;
    final int totalCount;

    if (rawData is Map<String, dynamic> && rawData['data'] is List) {
      // Laravel's standard paginator shape, nested inside `data`:
      // { data: [...], total: N, ... } or { data: [...], meta: {total: N} }.
      items = rawData['data'] as List;
      final metaTotal = rawData['meta'];
      totalCount =
          (rawData['total'] as num?)?.toInt() ??
          (metaTotal is Map ? (metaTotal['total'] as num?)?.toInt() : null) ??
          items.length;
    } else if (rawData is List) {
      // A flat list — no pagination wrapper at all.
      items = rawData;
      totalCount = items.length;
    } else {
      items = const [];
      totalCount = 0;
    }

    // Per-alert parsing lives on the model now (AlertModel.fromJson),
    // so the network path and the Isar cache can't drift into two
    // different readings of the same payload.
    final alerts = items
        .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return (alerts: alerts, totalCount: totalCount);
  }
}
