import '../../evacuation_centers/domain/entities/evacuation_center.dart';
import '../../staff_auth/domain/entities/staff_session.dart';

/// Whether [session] may change [center]'s details (backend step 7):
/// `centers.edit` is for barangay officials, for **any** center of their
/// own barangay (no longer only the ones they created). CSWD reviews
/// centers and no longer edits them. A display decision only: the
/// server stays the authority and a 403 is still handled.
///
/// [center] must come from the staff detail (`fromStaffJson`), the only
/// source that carries `barangayId` reliably.
bool canEditCenter({
  required EvacuationCenter center,
  required StaffSession session,
}) {
  return session.can(StaffPermission.centersEdit) &&
      session.barangayId != null &&
      center.barangayId == session.barangayId;
}
