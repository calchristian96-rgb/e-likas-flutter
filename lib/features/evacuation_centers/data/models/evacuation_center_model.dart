import '../../domain/entities/evacuation_center.dart';

/// The data-layer shape of an evacuation center: doubles as the Drift
/// cache row *and* the JSON model for `/public/evacuation-centers`,
/// `/public/evacuation-centers/nearest`, the GIS GeoJSON feature
/// properties from `/public/gis/map-data`, and (since Part 2) the
/// authenticated staff `EvacuationCenterResource` shape from
/// `GET/POST/PATCH /evacuation-centers`.
///
/// These response shapes don't return identical field sets (verified
/// against app/Http/Controllers/Api/PublicController.php,
/// GisController.php, and EvacuationCenterController.php): the
/// `/nearest` endpoint's raw SQL select omits `barangay`,
/// `current_occupancy`, and `occupancy_percent`; the GIS feature
/// properties omit `address`; and only the authenticated staff
/// resource includes `barangay_id`, `capacity_families`, camp-manager
/// fields, and `created_by`. Those fields are therefore nullable here —
/// missing rather than fabricated when a given endpoint doesn't
/// provide them.
///
/// Deliberately plain Dart rather than Freezed, matching every other
/// Drift-backed model in this app — Freezed stays available for any
/// future model that doesn't also need to round-trip through Drift's
/// generated companion/row classes.
class EvacuationCenterModel {
  EvacuationCenterModel({
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

  /// The backend's own numeric id, used directly as the Drift primary
  /// key too — no separate auto-increment id. The backend's id is
  /// already guaranteed unique, so it can serve as the primary key
  /// directly, which also simplifies the local datasource's upsert
  /// logic — `insertOnConflictUpdate` naturally updates the existing
  /// row whenever `id` matches, no manual match-and-copy step needed.
  final int id;

  final String name;
  final String type;

  /// Always present from `/evacuation-centers` and `/evacuation-centers
  /// /nearest`; absent from GIS feature properties (see class doc).
  final String? address;

  /// Always present from `/evacuation-centers` and GIS feature
  /// properties; absent from `/evacuation-centers/nearest` (see class
  /// doc).
  final String? barangay;

  /// Staff-only — see [EvacuationCenter.barangayId]'s doc comment.
  final int? barangayId;

  /// Genuinely nullable on the current backend — see
  /// [EvacuationCenter.latitude]'s doc comment.
  final double? latitude;
  final double? longitude;
  final int capacityPersons;

  /// Staff-only — see [EvacuationCenter.capacityFamilies]'s doc comment.
  final int? capacityFamilies;

  /// Absent from `/evacuation-centers/nearest` (see class doc).
  final int? currentOccupancy;

  /// Absent from `/evacuation-centers/nearest` (see class doc).
  final double? occupancyPercent;
  final String status;
  final double? distanceMeters;

  /// Real on the current backend: `EvacuationCenter::photo_url` (a
  /// resolved `Storage::disk('public')->url($photo_path)` URL),
  /// returned by `GisController::mapData()`'s feature properties and
  /// the staff `EvacuationCenterResource`. **Absent from `fromJson`'s
  /// two endpoints** (`/public/evacuation-centers`, `/public/
  /// evacuation-centers/nearest`) — neither resident-facing response
  /// includes it. See [EvacuationCenter.photoUrl]'s doc comment for
  /// what that means for which screens actually see a photo.
  final String? photoUrl;

  /// Staff-only — see [EvacuationCenter.createdBy]'s doc comment.
  final int? createdBy;

  /// Staff-only.
  final String? campManagerName;

  /// Staff-only.
  final String? campManagerContact;

  factory EvacuationCenterModel.fromJson(Map<String, dynamic> json) {
    return EvacuationCenterModel(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      address: json['address'] as String,
      barangay: json['barangay'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      // `capacity_persons` is a nullable DB column (confirmed against
      // the base migration) that this endpoint passes through
      // unguarded — defaults to 0 rather than force-casting, which
      // would crash parsing for any center with no capacity set yet.
      capacityPersons: (json['capacity_persons'] as num?)?.toInt() ?? 0,
      currentOccupancy: json['current_occupancy'] as int?,
      occupancyPercent: (json['occupancy_percent'] as num?)?.toDouble(),
      status: json['status'] as String,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      photoUrl: json['photo_url'] as String?,
    );
  }

  /// Parses a GeoJSON `Point` Feature from `/public/gis/map-data` — the
  /// same conceptual center, different envelope shape than
  /// [fromJson]'s flat `/evacuation-centers` JSON. Added for Module 3
  /// (the map feature); [fromJson] above is unchanged.
  ///
  /// GeoJSON coordinate order is always `[longitude, latitude]` — the
  /// opposite of how most people say "lat, lng" out loud — getting
  /// this backwards would silently place every marker in the wrong
  /// spot rather than error, so it's worth calling out explicitly here
  /// rather than trusting it to be obvious from the code alone.
  ///
  /// `coordinates` is read defensively (null/short list → null lat/lng)
  /// rather than force-cast — `GisController::mapData()` actually
  /// excludes null-coordinate centers from this response with its own
  /// `whereNotNull('latitude')->whereNotNull('longitude')` query
  /// guard, so every feature reaching here today does have real
  /// coordinates, but parsing still doesn't assume that's guaranteed
  /// to stay true. See [EvacuationCenter.latitude]'s doc comment.
  factory EvacuationCenterModel.fromGeoJsonFeature(
    Map<String, dynamic> properties,
    Map<String, dynamic>? geometry,
  ) {
    final coordinates = (geometry?['coordinates'] as List?)?.cast<num>();
    final hasCoordinates = coordinates != null && coordinates.length >= 2;
    return EvacuationCenterModel(
      id: properties['id'] as int,
      name: properties['name'] as String,
      type: properties['type'] as String,
      address: properties['address'] as String?,
      barangay: properties['barangay'] as String,
      // [lng, lat] — index 1 is lat, index 0 is lng.
      latitude: hasCoordinates ? coordinates.elementAt(1).toDouble() : null,
      longitude: hasCoordinates ? coordinates.elementAt(0).toDouble() : null,
      // Same nullable-column defensiveness as `fromJson` above.
      capacityPersons: (properties['capacity_persons'] as num?)?.toInt() ?? 0,
      currentOccupancy: properties['current_occupancy'] as int,
      occupancyPercent: (properties['occupancy_percent'] as num).toDouble(),
      status: properties['status'] as String,
      distanceMeters: null,
      photoUrl: properties['photo_url'] as String?,
    );
  }

  /// Parses the authenticated staff `EvacuationCenterResource` shape —
  /// `GET/POST/PATCH /evacuation-centers[/{id}]` (Part 2). Verified
  /// directly against `app/Http/Resources/EvacuationCenterResource.php`
  /// on `elikas-backend-main (4)`. Distinct envelope from [fromJson]:
  /// `barangay` is a nested `{id, name}` object here (not a flat
  /// string), and this is the only shape carrying `barangay_id`,
  /// `capacity_families`, camp-manager fields, and `created_by` at
  /// all — none of the resident-facing endpoints return them.
  factory EvacuationCenterModel.fromStaffJson(Map<String, dynamic> json) {
    final barangay = json['barangay'] as Map<String, dynamic>?;
    return EvacuationCenterModel(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      address: json['address'] as String?,
      barangay: barangay?['name'] as String?,
      barangayId: barangay?['id'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      capacityPersons: (json['capacity_persons'] as num?)?.toInt() ?? 0,
      capacityFamilies: (json['capacity_families'] as num?)?.toInt(),
      currentOccupancy: (json['current_occupancy'] as num?)?.toInt(),
      occupancyPercent: (json['occupancy_percent'] as num?)?.toDouble(),
      status: json['status'] as String,
      photoUrl: json['photo_url'] as String?,
      createdBy: (json['created_by'] as num?)?.toInt(),
      campManagerName: json['camp_manager_name'] as String?,
      campManagerContact: json['camp_manager_contact'] as String?,
    );
  }

  /// Merges `this` (a freshly-fetched model) over [existing] (whatever
  /// was already cached for the same [id], if anything) — the fix for
  /// a real device bug: `/public/evacuation-centers` never returns
  /// `photo_url`/`barangay_id`/`capacity_families`/camp-manager
  /// fields/`created_by` at all (confirmed against
  /// `PublicController::evacuationCenters()`), so writing its response
  /// straight into the same Isar row a GIS or staff fetch already
  /// populated would silently null those fields back out — exactly
  /// what made a just-uploaded center photo disappear the moment the
  /// public list refreshed after a successful staff upload.
  ///
  /// Deliberately narrow: only fields that are *structurally* absent
  /// from *every* endpoint this doesn't come from are merge-preserved
  /// unconditionally (`address`, `barangayId`, `capacityFamilies`,
  /// `campManagerName`, `campManagerContact`, `createdBy` — each is
  /// either always present with a real value or always absent
  /// entirely, by endpoint, never "present but legitimately null" —
  /// `address` is `required` on both FormRequests, and the other five
  /// exist only on the authenticated staff resource). `latitude`/
  /// `longitude` are never merged — every endpoint that returns them
  /// treats a null value as meaningful (no confirmed location yet),
  /// so a real "location cleared" must always propagate. `barangay`
  /// (the display name)/`currentOccupancy`/`occupancyPercent` are
  /// left unmerged too — `/nearest` omits them structurally, but
  /// `occupancyPercent` can also be a legitimate, meaningful `null`
  /// from a non-`/nearest` response (no capacity set), which this
  /// model has no way to tell apart from "endpoint doesn't know" —
  /// merging those would risk showing stale occupancy instead of a
  /// genuine change, a worse failure mode than the narrower gap of
  /// occasionally re-blanking them from a `/nearest` response (a
  /// pre-existing, lower-visibility limitation, not part of this fix).
  ///
  /// [photoUrlIsAuthoritative] is the one field-specific exception:
  /// true for GIS (`fromGeoJsonFeature`) and the staff resource
  /// (`fromStaffJson`), both of which always include the real
  /// `photo_url` key (even when its value is null, meaning "genuinely
  /// no photo") — their value is trusted outright, never merged.
  /// False for `fromJson` (the public list/nearest paths), which
  /// never includes the key at all, so its always-null `photoUrl`
  /// must defer to whatever richer source already cached one.
  EvacuationCenterModel mergeOverExisting(
    EvacuationCenterModel? existing, {
    bool photoUrlIsAuthoritative = false,
  }) {
    if (existing == null) return this;
    return EvacuationCenterModel(
      id: id,
      name: name,
      type: type,
      address: address ?? existing.address,
      barangay: barangay,
      barangayId: barangayId ?? existing.barangayId,
      latitude: latitude,
      longitude: longitude,
      capacityPersons: capacityPersons,
      capacityFamilies: capacityFamilies ?? existing.capacityFamilies,
      currentOccupancy: currentOccupancy,
      occupancyPercent: occupancyPercent,
      status: status,
      distanceMeters: distanceMeters,
      photoUrl: photoUrlIsAuthoritative
          ? photoUrl
          : (photoUrl ?? existing.photoUrl),
      createdBy: createdBy ?? existing.createdBy,
      campManagerName: campManagerName ?? existing.campManagerName,
      campManagerContact: campManagerContact ?? existing.campManagerContact,
    );
  }

  EvacuationCenter toEntity() {
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
      photoUrl: photoUrl,
      status: status,
      distanceMeters: distanceMeters,
      createdBy: createdBy,
      campManagerName: campManagerName,
      campManagerContact: campManagerContact,
    );
  }
}
