import 'package:dio/dio.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/staff_api_error_mapper.dart';
import '../../../evacuation_centers/data/datasources/evacuation_centers_local_datasource.dart';
import '../../../evacuation_centers/domain/entities/evacuation_center.dart';
import '../../domain/repositories/staff_evacuation_centers_repository.dart';
import '../datasources/staff_evacuation_centers_remote_datasource.dart';

/// Online only (a fresh detail every time). A newer photo URL is copied
/// into the public cache only for a center residents already see, so
/// pending centers and staff-only fields never reach it (A3).
class StaffEvacuationCentersRepositoryImpl
    implements StaffEvacuationCentersRepository {
  StaffEvacuationCentersRepositoryImpl(
    this._remote,
    this._connectivity,
    this._residentCache,
  );

  final StaffEvacuationCentersRemoteDataSource _remote;
  final ConnectivityService _connectivity;
  final EvacuationCentersLocalDatasource _residentCache;

  @override
  Future<Result<EvacuationCenter>> getCenterDetail(int id) async {
    if (!await _connectivity.hasConnection) {
      return const Failed(
        NetworkFailure('A center\'s details need an internet connection.'),
      );
    }
    try {
      final model = await _remote.getCenter(id);
      final photoUrl = model.photoUrl;
      if (photoUrl != null) {
        try {
          await _residentCache.updatePhotoUrl(model.id, photoUrl);
        } catch (_) {
          // Best effort: never turns a good read into an error.
        }
      }
      return Success(model.toEntity());
    } on DioException catch (e) {
      return Failed(mapStaffDioError(e));
    }
  }
}
