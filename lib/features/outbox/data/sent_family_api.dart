import 'package:dio/dio.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/staff_api_client.dart';
import '../../../core/network/staff_api_error_mapper.dart';
import '../domain/sent_family.dart';

/// Corrects a sent registration on the server, online only, through the
/// endpoints the web uses (backend routes/api.php):
/// - `GET /families/{id}`: the family and its members as saved;
/// - `PATCH /evacuees/{id}`: one person's details
///   (EvacueeController::update);
/// - `PATCH /families/{id}/household`: the head and the household
///   answers (FamilyController::updateHousehold).
/// A refusal comes back as the server's own [Failure] (422 field errors
/// in [ValidationFailure.fieldErrors]).
class SentFamilyApi {
  SentFamilyApi(this._api, this._connectivity);

  final StaffApiClient _api;
  final ConnectivityService _connectivity;

  Future<Result<SentFamily>> getFamily(int id) => _online(() async {
    final response = await _api.get('/families/$id');
    final data = (response.data as Map)['data'] as Map<String, dynamic>;
    return SentFamily.fromJson(data);
  });

  Future<Result<SentMember>> updateMember(
    int evacueeId,
    Map<String, dynamic> body,
  ) => _online(() async {
    final response = await _api.patch('/evacuees/$evacueeId', data: body);
    final data = (response.data as Map)['data'] as Map<String, dynamic>;
    return SentMember.fromJson(data);
  });

  Future<Result<void>> updateHousehold(
    int familyId,
    Map<String, dynamic> body,
  ) => _online(() async {
    await _api.patch('/families/$familyId/household', data: body);
  });

  Future<Result<T>> _online<T>(Future<T> Function() request) async {
    if (!await _connectivity.hasConnection) {
      return const Failed(NeedsConnectionFailure());
    }
    try {
      return Success(await request());
    } on DioException catch (e) {
      return Failed(mapStaffDioError(e));
    }
  }
}

/// Editing a sent record needs the server: shown as its own message.
class NeedsConnectionFailure extends NetworkFailure {
  const NeedsConnectionFailure()
    : super('Editing a sent record needs an internet connection.');
}
