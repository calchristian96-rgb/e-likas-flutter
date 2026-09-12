import '../../../../core/network/staff_api_client.dart';

/// `GET /families` — server-authorized, paginated (confirmed against
/// `FamilyController::index`: `barangay_id` is force-applied for a
/// barangay official and ignored/optional for administrator/CSWD
/// personnel; this datasource sends no filter of its own and simply
/// returns whatever the backend decided this account may see).
///
/// The response is double-nested — the app's own `{success, message,
/// data}` envelope wraps Laravel's own paginator shape (`{data, links,
/// meta}`) — confirmed against the actual `FamilyController::index`
/// response.
class RegisteredFamiliesRemoteDataSource {
  RegisteredFamiliesRemoteDataSource(this._client);

  final StaffApiClient _client;

  /// A safety cap on how many pages this ever fetches in one call —
  /// this app targets a single city's staff roster, not an
  /// unbounded dataset, so 50 pages at 100/page (5,000 families) is
  /// generously above any realistic ceiling while still guaranteeing
  /// this loop can never run away indefinitely against a
  /// misbehaving/malicious backend response.
  static const _maxPages = 50;
  static const _perPage = 100;

  /// Every family page, concatenated — loops `page` until the
  /// backend's own `meta.last_page` says there's nothing left.
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final results = <Map<String, dynamic>>[];
    var page = 1;
    while (page <= _maxPages) {
      final response = await _client.get(
        '/families',
        queryParameters: {'per_page': _perPage, 'page': page},
      );
      final envelope = response.data as Map<String, dynamic>;
      final paginator = envelope['data'] as Map<String, dynamic>;
      final items = (paginator['data'] as List).cast<Map<String, dynamic>>();
      results.addAll(items);

      final meta = paginator['meta'] as Map<String, dynamic>?;
      final lastPage = meta?['last_page'] as int? ?? page;
      if (page >= lastPage || items.isEmpty) break;
      page++;
    }
    return results;
  }
}
