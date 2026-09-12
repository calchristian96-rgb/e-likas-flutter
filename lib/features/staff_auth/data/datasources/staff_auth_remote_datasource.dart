import '../../../../core/network/staff_api_client.dart';

/// Raw calls against the three staff auth endpoints. Returns decoded
/// JSON maps straight from `data.*` — parsing into [StaffSession]
/// happens one layer up in the repository, same layering every other
/// feature's remote datasource uses.
class StaffAuthRemoteDataSource {
  StaffAuthRemoteDataSource(this._client);

  final StaffApiClient _client;

  /// Returns the `data` object of a successful login response:
  /// `{ user: {...UserResource}, token: "1|..." }`.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
  }

  Future<void> logout() => _client.post('/auth/logout');

  /// Returns the `data` object: the `UserResource` fields directly.
  Future<Map<String, dynamic>> me() async {
    final response = await _client.get('/auth/me');
    return (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
  }
}
