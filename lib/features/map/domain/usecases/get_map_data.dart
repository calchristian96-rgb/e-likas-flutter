import '../../../../core/error/result.dart';
import '../entities/map_data.dart';
import '../repositories/map_repository.dart';

class GetMapData {
  const GetMapData(this._repository);

  final MapRepository _repository;

  Future<Result<MapData>> call() => _repository.getMapData();
}
