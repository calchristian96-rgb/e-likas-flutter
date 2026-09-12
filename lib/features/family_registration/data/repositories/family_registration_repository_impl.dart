import 'package:dio/dio.dart';

import '../../../../core/error/result.dart';
import '../../../../core/network/staff_api_error_mapper.dart';
import '../../domain/entities/family_registration_draft.dart';
import '../../domain/repositories/family_registration_repository.dart';
import '../datasources/family_registration_remote_datasource.dart';

class FamilyRegistrationRepositoryImpl implements FamilyRegistrationRepository {
  FamilyRegistrationRepositoryImpl(this._remote);

  final FamilyRegistrationRemoteDataSource _remote;

  @override
  Future<Result<int>> submit(FamilyRegistrationDraft draft) async {
    try {
      final data = await _remote.register(draft.toJson());
      return Success(data['id'] as int);
    } on DioException catch (e) {
      return Failed(mapStaffDioError(e));
    }
  }
}
