import '../../../../core/error/result.dart';
import '../repositories/alerts_repository.dart';

class GetAlerts {
  const GetAlerts(this._repository);

  final AlertsRepository _repository;

  Future<Result<AlertsFeed>> call({int limit = 20}) {
    return _repository.getAlerts(limit: limit);
  }
}
