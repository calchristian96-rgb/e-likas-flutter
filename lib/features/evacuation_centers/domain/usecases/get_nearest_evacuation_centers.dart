import '../../../../core/error/result.dart';
import '../entities/evacuation_center.dart';
import '../repositories/evacuation_centers_repository.dart';

class GetNearestEvacuationCenters {
  const GetNearestEvacuationCenters(this._repository);

  final EvacuationCentersRepository _repository;

  Future<Result<List<EvacuationCenter>>> call({
    required double latitude,
    required double longitude,
    int limit = 10,
  }) {
    return _repository.getNearestCenters(
      latitude: latitude,
      longitude: longitude,
      limit: limit,
    );
  }
}
