import '../../../../core/error/result.dart';
import '../entities/evacuation_center.dart';
import '../repositories/evacuation_centers_repository.dart';

class GetAllEvacuationCenters {
  const GetAllEvacuationCenters(this._repository);

  final EvacuationCentersRepository _repository;

  Future<Result<List<EvacuationCenter>>> call() {
    return _repository.getAllCenters();
  }
}
