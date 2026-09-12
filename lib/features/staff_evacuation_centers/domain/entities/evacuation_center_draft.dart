import '../../../evacuation_centers/domain/entities/evacuation_center.dart';

/// A `POST`/`PATCH /evacuation-centers` request body, field-for-field —
/// verified against `StoreEvacuationCenterRequest`/
/// `UpdateEvacuationCenterRequest` on `elikas-backend-main (4)`. Every
/// field here is one the backend actually accepts; nothing is
/// invented. The `photo` file itself is handled separately by the
/// form/repository (a draft is plain data, not a multipart body).
class EvacuationCenterDraft {
  const EvacuationCenterDraft({
    this.barangayId,
    this.name = '',
    this.type,
    this.address = '',
    this.latitude,
    this.longitude,
    this.capacityFamilies,
    this.capacityPersons,
    this.campManagerName,
    this.campManagerContact,
    // Matches the `evacuation_centers.status` column's own DB default
    // — a sensible starting point for a brand-new center, not a guess.
    this.status = 'on_standby',
  });

  final int? barangayId;
  final String name;

  /// 'school' | 'covered_court' | 'church' | 'barangay_hall' |
  /// 'gymnasium' | 'other' — the exact `StoreEvacuationCenterRequest`
  /// enum, no other values accepted.
  final String? type;

  final String address;

  /// Optional — `StoreEvacuationCenterRequest` validates these as
  /// `nullable`, `required_with` each other (a half-set pair is
  /// rejected). Null means "no confirmed map location yet," never
  /// `0,0` — see `EvacuationCenter.latitude`'s doc comment.
  final double? latitude;
  final double? longitude;

  final int? capacityFamilies;
  final int? capacityPersons;
  final String? campManagerName;
  final String? campManagerContact;

  /// 'active' | 'full' | 'closed' | 'on_standby' — the exact backend
  /// enum, required on create.
  final String status;

  bool get hasLocation => latitude != null && longitude != null;

  /// True once every backend-required field is present — gates the
  /// submit button. Field-level validators still run in the form
  /// itself; this is a cheap pre-check, not a replacement for the
  /// backend's own 422 response.
  bool get isSubmittable =>
      barangayId != null &&
      name.trim().isNotEmpty &&
      type != null &&
      address.trim().isNotEmpty &&
      status.isNotEmpty;

  EvacuationCenterDraft copyWith({
    int? barangayId,
    String? name,
    String? type,
    String? address,
    double? latitude,
    double? longitude,
    bool clearLocation = false,
    int? capacityFamilies,
    bool clearCapacityFamilies = false,
    int? capacityPersons,
    bool clearCapacityPersons = false,
    String? campManagerName,
    bool clearCampManagerName = false,
    String? campManagerContact,
    bool clearCampManagerContact = false,
    String? status,
  }) {
    return EvacuationCenterDraft(
      barangayId: barangayId ?? this.barangayId,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      latitude: clearLocation ? null : (latitude ?? this.latitude),
      longitude: clearLocation ? null : (longitude ?? this.longitude),
      capacityFamilies: clearCapacityFamilies
          ? null
          : (capacityFamilies ?? this.capacityFamilies),
      capacityPersons: clearCapacityPersons
          ? null
          : (capacityPersons ?? this.capacityPersons),
      campManagerName: clearCampManagerName
          ? null
          : (campManagerName ?? this.campManagerName),
      campManagerContact: clearCampManagerContact
          ? null
          : (campManagerContact ?? this.campManagerContact),
      status: status ?? this.status,
    );
  }

  /// JSON request body — every field always included (even as
  /// explicit `null`) rather than selectively omitted. This matters:
  /// verified against `UpdateEvacuationCenterRequest`, `capacity_
  /// families`/`capacity_persons`/`camp_manager_name`/`camp_manager_
  /// contact` have **no** `sometimes` rule, so an *omitted* key isn't
  /// "leave unchanged" the way it is for `name`/`type`/`address`/
  /// `status`/`latitude`/`longitude` (which do have `sometimes`) — an
  /// absent key there still validates as `null` and clears the
  /// existing value. Always sending every field with its real current
  /// (possibly null) value sidesteps needing to track that
  /// distinction per field and behaves correctly for both create and
  /// update either way.
  Map<String, dynamic> toJsonBody() {
    return {
      'barangay_id': barangayId,
      'name': name.trim(),
      'type': type,
      'address': address.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'capacity_families': capacityFamilies,
      'capacity_persons': capacityPersons,
      'camp_manager_name': _blankToNull(campManagerName),
      'camp_manager_contact': _blankToNull(campManagerContact),
      'status': status,
    };
  }

  /// The same fields as [toJsonBody], but as `String`-only values for
  /// `dio`'s `FormData.fromMap` (multipart requests can't carry a
  /// literal `null`) — null/empty fields are simply omitted here. See
  /// `StaffEvacuationCentersRemoteDataSource` for why a field omitted
  /// this way can, for `latitude`/`longitude` specifically, fail to
  /// clear a previously-set location in the one edge case where a
  /// photo is changed in the same submit as clearing location, and
  /// how that's handled with a second request instead.
  Map<String, String> toMultipartFields() {
    final fields = <String, String>{
      'name': name.trim(),
      'address': address.trim(),
      'status': status,
    };
    if (barangayId != null) fields['barangay_id'] = '$barangayId';
    if (type != null) fields['type'] = type!;
    if (latitude != null) fields['latitude'] = '$latitude';
    if (longitude != null) fields['longitude'] = '$longitude';
    if (capacityFamilies != null) {
      fields['capacity_families'] = '$capacityFamilies';
    }
    if (capacityPersons != null) {
      fields['capacity_persons'] = '$capacityPersons';
    }
    final managerName = _blankToNull(campManagerName);
    if (managerName != null) fields['camp_manager_name'] = managerName;
    final managerContact = _blankToNull(campManagerContact);
    if (managerContact != null) {
      fields['camp_manager_contact'] = managerContact;
    }
    return fields;
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  factory EvacuationCenterDraft.fromEntity(EvacuationCenter center) {
    return EvacuationCenterDraft(
      barangayId: center.barangayId,
      name: center.name,
      type: center.type,
      address: center.address ?? '',
      latitude: center.latitude,
      longitude: center.longitude,
      capacityFamilies: center.capacityFamilies,
      capacityPersons: center.capacityPersons == 0
          ? null
          : center.capacityPersons,
      campManagerName: center.campManagerName,
      campManagerContact: center.campManagerContact,
      status: center.status,
    );
  }
}
