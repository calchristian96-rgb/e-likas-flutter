/// One cached `GET /families` list row — field set deliberately
/// minimal (see `CachedFamilyModel`'s doc comment for the PII-budget
/// reasoning): only what "All Evacuees"/"Registered Families" display,
/// barangay grouping, local duplicate-name checking, and a read-only
/// record-inspection view actually need. No date of birth, contact
/// number, or sectoral flags are cached here — those stay exclusively
/// in the pending-registration queue's payload, which is deleted the
/// moment a sync succeeds.
class RegisteredFamily {
  const RegisteredFamily({
    required this.id,
    required this.barangayId,
    required this.barangayName,
    required this.headOfFamilyName,
    this.homeAddress,
    required this.memberCount,
    this.evacuationCenterName,
    this.is4psBeneficiary = false,
    this.createdAt,
    this.memberNames = const [],
  });

  /// The backend's real `families.id` — used only to link back to the
  /// same record on repeat syncs (`putAll` upserts by this), never
  /// shown to staff.
  final int id;

  final int? barangayId;

  /// "Unknown barangay" (localized at the presentation layer) when the
  /// backend didn't return a barangay — grouping still needs a bucket
  /// to put the row in.
  final String barangayName;

  /// Empty when the family has no member marked head — the
  /// presentation layer shows a localized "Unnamed family" instead of
  /// blank space.
  final String headOfFamilyName;

  final String? homeAddress;
  final int memberCount;

  /// Null when the family isn't currently linked to an evacuation
  /// center record — the backend derives this per-family from the
  /// most recent evacuation record across its members (see
  /// `FamilyResource::evacuation_center`), so it's the closest
  /// available signal to "inside a center" vs "outside a center,"
  /// rather than a literal `displacement_type` column (the backend
  /// doesn't return one at the family level).
  final String? evacuationCenterName;
  final bool is4psBeneficiary;
  final DateTime? createdAt;

  /// Every member's full name, exactly as returned by
  /// `EvacueeResource.full_name` — the only per-member data cached, and
  /// only because local duplicate-name checking (Phase 3) and the
  /// record-inspection view both need it. Never sourced from anywhere
  /// but a barangay this staff account is authorized to see (the
  /// backend enforces that scoping; this cache only ever holds what
  /// the authenticated `GET /families` response actually returned).
  final List<String> memberNames;
}
