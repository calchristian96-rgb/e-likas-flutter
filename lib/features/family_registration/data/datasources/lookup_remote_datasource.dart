import '../../../../core/network/staff_api_client.dart';
import '../models/lookup_barangay_model.dart';
import '../models/lookup_evacuation_center_model.dart';
import '../models/lookup_evacuation_event_model.dart';

/// The three authenticated lookup-list endpoints
/// (`role:administrator,cswd_personnel,barangay_official`), each
/// wrapped in the app's usual `{success, message, data}` envelope.
class LookupRemoteDataSource {
  LookupRemoteDataSource(this._client);

  final StaffApiClient _client;

  Future<List<LookupBarangayModel>> getBarangays() async {
    final response = await _client.get('/barangays');
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data
        .map((e) => LookupBarangayModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LookupEvacuationEventModel>> getEvacuationEvents() async {
    final response = await _client.get('/evacuation-events');
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data
        .map(
          (e) => LookupEvacuationEventModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// [eventId]: the selected event, so the figures and the status are
  /// that event's (backend d17f6de); null = the user's selected event
  /// on the server.
  Future<List<LookupEvacuationCenterModel>> getEvacuationCenters({
    int? eventId,
  }) async {
    // Rejected ones too, so an official sees why a center is unusable.
    final response = await _client.get(
      '/evacuation-centers',
      queryParameters: {'include_rejected': 1, 'evacuation_event_id': ?eventId},
    );
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data
        .map(
          (e) => LookupEvacuationCenterModel.fromJson(
            e as Map<String, dynamic>,
            eventId: eventId,
          ),
        )
        .toList();
  }
}
