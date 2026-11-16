import '../../../../core/error/result.dart';
import '../../../evacuation_centers/domain/entities/evacuation_center.dart';

/// The authenticated detail of one center. Center details are added and
/// edited on the web (C24); the phone sets a center's location through
/// `POST /gis/centers/{id}/location` (the offline queue, C19).
abstract class StaffEvacuationCentersRepository {
  Future<Result<EvacuationCenter>> getCenterDetail(int id);
}
