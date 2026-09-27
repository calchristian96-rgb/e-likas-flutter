import '../../../../core/error/result.dart';
import '../entities/evacuation_centers_snapshot.dart';
import '../repositories/evacuation_centers_repository.dart';

class GetAllEvacuationCenters {
  const GetAllEvacuationCenters(this._repository);

  final EvacuationCentersRepository _repository;

  Future<Result<EvacuationCentersSnapshot>> call() {
    return _repository.getAllCenters();
  }
}
