import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/center_facility_model.dart';
import '../models/evacuation_center_model.dart';

class EvacuationCentersRemoteDatasource {
  const EvacuationCentersRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<EvacuationCenterModel>> getAllCenters() async {
    final response = await _apiClient.get(ApiEndpoints.evacuationCenters);
    return _parseList(response.data as Map<String, dynamic>);
  }

  /// `GET public/evacuation-centers/{id}` — only the `facilities` array
  /// is read here; every other field this endpoint returns (status,
  /// capacity, occupancy, coordinates) is already covered by the
  /// existing list-based `EvacuationCenterModel`/`centerByIdProvider`
  /// flow and deliberately left untouched rather than duplicated. Photo
  /// is the one exception — see [getCenterPhotoUrl], which reads this
  /// same endpoint's `photo_url` for a different purpose.
  Future<List<CenterFacilityModel>> getCenterFacilities(int centerId) async {
    final response = await _apiClient.get(
      ApiEndpoints.evacuationCenterDetail(centerId),
    );
    final envelope = response.data as Map<String, dynamic>;
    final data = envelope['data'] as Map<String, dynamic>;
    final facilities = data['facilities'] as List? ?? const [];
    return facilities
        .map((e) => CenterFacilityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET public/evacuation-centers/{id}` — only `photo_url` is read
  /// here. Used to backfill a real photo for a center whose cached row
  /// doesn't have one yet: `public/evacuation-centers` (the plain
  /// list, confirmed against `PublicController::evacuationCenters()`
  /// and a live production check) never returns `photo_url` at all —
  /// only this detail endpoint and `public/gis/map-data` do. Without
  /// this, a resident who opens Center Details without ever having
  /// visited the GIS map first would see no photo for a center that
  /// genuinely has one uploaded on the backend.
  Future<String?> getCenterPhotoUrl(int centerId) async {
    final response = await _apiClient.get(
      ApiEndpoints.evacuationCenterDetail(centerId),
    );
    final envelope = response.data as Map<String, dynamic>;
    final data = envelope['data'] as Map<String, dynamic>;
    return data['photo_url'] as String?;
  }

  Future<List<EvacuationCenterModel>> getNearestCenters({
    required double latitude,
    required double longitude,
    int limit = 10,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.nearestEvacuationCenters,
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'limit': limit,
      },
    );
    return _parseList(response.data as Map<String, dynamic>);
  }

  List<EvacuationCenterModel> _parseList(Map<String, dynamic> json) {
    final parsed = ApiResponse<List<EvacuationCenterModel>>.fromJson(
      json,
      (data) => (data as List)
          .map((e) => EvacuationCenterModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return parsed.data;
  }
}
