import '../../evacuation_centers/domain/entities/evacuation_center.dart';
import '../../staff_auth/domain/entities/staff_session.dart';

/// Whether [session] may edit [center] — a direct mirror of
/// `EvacuationCenterController::update()`'s own check on
/// `elikas-backend-main (4)`:
///
/// ```php
/// if ($user->isBarangayOfficial() && $evacuationCenter->created_by !== $user->id) {
///     return $this->error('You may only edit evacuation centers you created yourself.', 403);
/// }
/// ```
///
/// Administrator/CSWD personnel are unrestricted; a barangay official
/// may only edit a center they themselves created (`created_by`, not
/// a barangay match — two different officials can serve the same
/// barangay over time). [center.createdBy] is only ever populated
/// from the authenticated staff detail response
/// (`EvacuationCenterModel.fromStaffJson`) — this function should
/// never be called against a center sourced from a public/resident
/// endpoint, where `createdBy` is always null and this would
/// incorrectly read as "not editable" for every role.
///
/// This is a client-side *display* decision only — hiding a button a
/// barangay official can't use anyway. The server remains the actual
/// authority: `updateCenter` still handles a 403 safely even if this
/// ever disagrees with it (e.g. ownership changed via `assignOwner`
/// between page loads).
bool canEditCenter({
  required EvacuationCenter center,
  required StaffSession session,
}) {
  if (session.role == 'barangay_official') {
    return center.createdBy == session.id;
  }
  return true;
}
