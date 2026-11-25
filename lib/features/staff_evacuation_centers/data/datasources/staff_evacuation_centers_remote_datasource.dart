import '../../../../core/network/staff_api_client.dart';
import '../../../evacuation_centers/data/models/evacuation_center_model.dart';

/// `GET /evacuation-centers/{id}`: the staff detail of one center (404
/// for a center this account may not see, backend step 7).
class StaffEvacuationCentersRemoteDataSource {
  StaffEvacuationCentersRemoteDataSource(this._client);

  final StaffApiClient _client;

  /// [eventId]: the figures and the status are that event's (backend
  /// d17f6de); null = the user's selected event on the server.
  Future<EvacuationCenterModel> getCenter(int id, {int? eventId}) async {
    final response = await _client.get(
      '/evacuation-centers/$id',
      queryParameters: {'evacuation_event_id': ?eventId},
    );
    return EvacuationCenterModel.fromStaffJson(
      (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }
}
