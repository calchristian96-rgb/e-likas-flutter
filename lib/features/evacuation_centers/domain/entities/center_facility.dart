/// One recorded facility-checklist row for an evacuation center, as
/// returned by `GET public/evacuation-centers/{id}` (verified against
/// `PublicController::evacuationCenter()` on `elikas-backend-main (7)`).
///
/// Only facilities that actually have a database record appear at all
/// — a center with no facilities recorded yet returns an empty list,
/// not all 19 known types pre-filled. The presentation layer is
/// responsible for reconciling this against the fixed 19-type
/// checklist (see `evacuationCenterFacilityTypeValues`).
class CenterFacility {
  const CenterFacility({
    required this.facilityType,
    required this.quantity,
    required this.isAvailable,
    this.concernsAndNeeds,
  });

  /// One of the 19 backend `facility_type` enum values — never
  /// invented client-side (see `evacuationCenterFacilityTypeValues`).
  final String facilityType;

  final int quantity;
  final bool isAvailable;

  /// Free-text staff note — present only when staff actually recorded
  /// one, most relevant when [isAvailable] is false (e.g. "toilet
  /// unavailable, awaiting repair"). Never fabricated when null.
  final String? concernsAndNeeds;
}
