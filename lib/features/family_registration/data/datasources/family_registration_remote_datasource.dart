import '../../../../core/network/staff_api_client.dart';

/// The one write endpoint this whole feature exists to call:
/// `POST /families/register` (confirmed — `POST /families` does not
/// exist on this backend). [submit] takes the already-built request
/// body (see `FamilyRegistrationDraft.toJson`) and returns the raw
/// created-family JSON on success; the caller decides what to do with
/// it (currently just the new family id).
class FamilyRegistrationRemoteDataSource {
  FamilyRegistrationRemoteDataSource(this._client);

  final StaffApiClient _client;

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final response = await _client.post('/families/register', data: payload);
    return (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
  }
}
