import '../../../../core/error/result.dart';
import '../entities/alert.dart';
import '../repositories/alerts_repository.dart';

class GetAlertById {
  const GetAlertById(this._repository);

  final AlertsRepository _repository;

  Future<Result<Alert>> call(int id) {
    return _repository.getAlertById(id);
  }
}
