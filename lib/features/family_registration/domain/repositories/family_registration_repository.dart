import '../../../../core/error/result.dart';
import '../entities/family_registration_draft.dart';

/// The single online submission path: `POST /families/register`.
///
/// Callers (the form's submit handler, and `StaffSyncService`) are
/// responsible for checking connectivity *before* calling this when
/// they already know they're offline — this repository doesn't skip
/// a doomed attempt on its own, it just reports whatever Dio/the
/// backend actually returns, mapped through [mapStaffDioError].
abstract class FamilyRegistrationRepository {
  /// Returns the created family's backend id on a confirmed 201.
  Future<Result<int>> submit(FamilyRegistrationDraft draft);
}
