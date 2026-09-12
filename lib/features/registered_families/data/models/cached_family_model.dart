import '../../../family_registration/data/models/pending_family_registration_model.dart'
    show fastHash;

/// One cached `GET /families` row, in the encrypted staff Drift
/// database — never the resident/public one.
///
/// Deliberately minimal: no date of birth, contact number, or
/// sectoral (PWD/pregnant/lactating/solo-parent/indigenous) flags are
/// cached here, even though the backend's `FamilyResource` includes
/// them per member. Those fields aren't needed for the "All
/// Evacuees"/"Registered Families" list, barangay grouping, local
/// duplicate-name checking, or the read-only record-inspection view —
/// the only four things this cache exists to serve — so they're left
/// uncached rather than duplicating sensitive data beyond what each
/// feature actually reads. Only [memberNames] carries any PII, and
/// only because duplicate-name checking and record inspection both
/// need names specifically.
class CachedFamilyModel {
  CachedFamilyModel({
    required this.id,
    required this.familyId,
    required this.ownerStaffId,
    this.barangayId,
    required this.barangayName,
    required this.headOfFamilyName,
    this.homeAddress,
    required this.memberCount,
    this.evacuationCenterName,
    this.is4psBeneficiary = false,
    this.createdAtEpochMs,
    this.memberNames = const [],
  });

  /// Derived from `ownerStaffId:familyId` via [fastHash] — a stable,
  /// deterministic id for the in-memory model even though the Drift
  /// table itself keys on the real `(familyId, ownerStaffId)` pair
  /// directly. Namespacing by owner in the id itself (rather
  /// than relying only on the [ownerStaffId] field) means two
  /// different staff accounts caching the same family id can never
  /// collide into a single row.
  final int id;

  /// The backend's real `families.id`.
  final int familyId;

  /// The authenticated staff user's real backend `id` — same
  /// ownership key and same reasoning as
  /// `PendingFamilyRegistrationModel.ownerStaffId`. Every read in
  /// `RegisteredFamiliesLocalDataSource` is scoped to this, so one
  /// account can never see another's cached family list on a shared
  /// device, and a barangay official's cache — already scoped
  /// server-side to their own barangay — can't leak into a
  /// differently-scoped account's view either.
  final int ownerStaffId;

  final int? barangayId;
  final String barangayName;
  final String headOfFamilyName;
  final String? homeAddress;
  final int memberCount;
  final String? evacuationCenterName;
  final bool is4psBeneficiary;
  final int? createdAtEpochMs;
  final List<String> memberNames;
}
