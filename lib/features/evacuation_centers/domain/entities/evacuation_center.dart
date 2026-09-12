/// A single evacuation center, as returned by the E-LIKAS public API.
///
/// Pure Dart — no Flutter, no package dependencies. This is the shape
/// every other layer (data, presentation) works with; only the data
/// layer's model class knows about JSON or the local cache.
class EvacuationCenter {
  const EvacuationCenter({
    required this.id,
    required this.name,
    required this.type,
    this.address,
    this.barangay,
    this.barangayId,
    required this.latitude,
    required this.longitude,
    required this.capacityPersons,
    this.capacityFamilies,
    this.currentOccupancy,
    this.occupancyPercent,
    required this.status,
    this.distanceMeters,
    this.photoUrl,
    this.createdBy,
    this.campManagerName,
    this.campManagerContact,
  });

  final int id;
  final String name;
  final String type;

  /// Not returned by the `/nearest` endpoint's response — see
  /// [EvacuationCenterModel].
  final String? address;

  /// Not returned by the `/nearest` endpoint's response — see
  /// [EvacuationCenterModel].
  final String? barangay;

  /// Only present when this center came from the authenticated staff
  /// `GET /evacuation-centers/{id}` response (`EvacuationCenterResource`
  /// returns `barangay: {id, name}`; the public endpoints only ever
  /// return the flat `barangay` name string above). Staff-only, needed
  /// to pre-select the right barangay when editing — see
  /// `EvacuationCenterModel.fromStaffJson`.
  final int? barangayId;

  /// Genuinely nullable on the current backend (`elikas-backend-main
  /// (4)`): the `evacuation_centers.latitude`/`longitude` columns were
  /// made nullable by `2026_08_20_000002_make_evacuation_center_
  /// location_optional.php`, and `StoreEvacuationCenterRequest`/
  /// `UpdateEvacuationCenterRequest` validate them as `nullable` (a
  /// center can be created with an address but no map location yet).
  /// Every response path that serializes a center now null-guards the
  /// cast instead of a bare `(float)`. A center missing coordinates
  /// degrades gracefully here — no marker, no fabricated `0,0`/
  /// city-fallback point — instead of crashing JSON parsing or
  /// silently mislocating it. See [EvacuationCenterModel.fromJson]'s
  /// doc comment.
  final double? latitude;
  final double? longitude;
  final int capacityPersons;

  /// Staff-only — not returned by any resident-facing endpoint (public
  /// list/nearest, GIS map data), only the authenticated staff
  /// `EvacuationCenterResource`.
  final int? capacityFamilies;

  /// Not returned by the `/nearest` endpoint's response — see
  /// [EvacuationCenterModel].
  final int? currentOccupancy;

  /// Not returned by the `/nearest` endpoint's response — see
  /// [EvacuationCenterModel].
  final double? occupancyPercent;
  final String status;

  /// Populated when this center came from the `/nearest` endpoint
  /// (server-computed distance) or was ranked client-side while
  /// offline — see [DistanceCalculator] in core/utils and the
  /// repository implementation's offline fallback path.
  final double? distanceMeters;

  /// Real on the current backend (`elikas-backend-main (4)`), sourced
  /// from `EvacuationCenter::getPhotoUrlAttribute()` (`photo_path` on
  /// the `public` disk, resolved to a full URL). Returned by the
  /// staff `EvacuationCenterResource` and by `GisController::
  /// mapData()`'s GeoJSON feature properties — **not** by either
  /// resident-facing public endpoint this feature actually calls
  /// (`/public/evacuation-centers`, `/public/evacuation-centers/
  /// nearest`), which still omit it entirely. In practice this means
  /// a center only carries a real photo here after being loaded via
  /// the GIS map (see [EvacuationCenterModel]'s doc comment on why
  /// the cache is shared across endpoints) — null otherwise, which
  /// [CenterPhotoCard] already renders as a plain placeholder.
  final String? photoUrl;

  /// Staff-only — the backend `users.id` of whoever created this
  /// center (`EvacuationCenter.created_by`), only returned by the
  /// authenticated staff resource. This is the actual server-side
  /// authorization key: a `barangay_official` may edit a center only
  /// when `createdBy == their own session id` (confirmed against
  /// `EvacuationCenterController::update()`'s exact check) — never
  /// derived from a barangay match, which the backend deliberately
  /// does not use for this decision.
  final int? createdBy;

  /// Staff-only, not returned by any resident-facing endpoint.
  final String? campManagerName;

  /// Staff-only, not returned by any resident-facing endpoint.
  final String? campManagerContact;

  /// `address` and `barangay` joined for display, omitting whichever
  /// one a given endpoint didn't provide instead of showing "null".
  String get displayLocation {
    return [
      address,
      barangay,
    ].where((part) => part != null && part.isNotEmpty).join(', ');
  }

  /// Whether this center has real coordinates to plot on a map or hand
  /// to a directions/maps app. False for a center missing one or both
  /// (see [latitude]'s doc comment — a real, not hypothetical, case on
  /// the current backend) — never treated as `0,0` or any other
  /// fallback point.
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Whether both occupancy fields are available to display — false
  /// for centers sourced from the `/nearest` endpoint.
  bool get hasOccupancyData =>
      currentOccupancy != null && occupancyPercent != null;

  /// `max(capacity - currentOccupancy, 0)`, or null when
  /// [currentOccupancy] isn't available to compute it from (the
  /// `/nearest` endpoint doesn't return it — see the class doc
  /// comment). Clamped at zero rather than allowed to go negative,
  /// since a center that's over its stated capacity still has no
  /// *available* slots, not a negative number of them.
  int? get availableSlots {
    final occupancy = currentOccupancy;
    if (occupancy == null) return null;
    final remaining = capacityPersons - occupancy;
    return remaining < 0 ? 0 : remaining;
  }

  EvacuationCenter copyWithDistance(double meters) {
    return EvacuationCenter(
      id: id,
      name: name,
      type: type,
      address: address,
      barangay: barangay,
      barangayId: barangayId,
      latitude: latitude,
      longitude: longitude,
      capacityPersons: capacityPersons,
      capacityFamilies: capacityFamilies,
      currentOccupancy: currentOccupancy,
      occupancyPercent: occupancyPercent,
      status: status,
      distanceMeters: meters,
      photoUrl: photoUrl,
      createdBy: createdBy,
      campManagerName: campManagerName,
      campManagerContact: campManagerContact,
    );
  }
}
