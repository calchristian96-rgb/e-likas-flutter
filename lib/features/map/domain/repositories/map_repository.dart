import '../../../../core/error/result.dart';
import '../entities/map_data.dart';

abstract class MapRepository {
  /// Map data (centers + hazard areas), network-first with cache
  /// fallback — same pattern as evacuation_centers.
  Future<Result<MapData>> getMapData();
}
