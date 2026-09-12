export '../../../../core/utils/fast_hash.dart' show fastHash;

/// One offline-queued (or being-synced) family registration.
///
/// [payloadJson] holds the exact `POST /families/register` request
/// body (see `FamilyRegistrationRemoteDataSource`) — the only place in
/// the app that keeps the full sensitive member list (names, DOB,
/// contact numbers, PWD/pregnancy/lactation/solo-parent/indigenous/
/// 4Ps flags) at rest, and only inside the encrypted staff Drift
/// database (`core/database/staff_database.dart`). It is deleted the
/// moment the backend confirms the registration (HTTP 201) — see
/// `StaffSyncService`. [headOfFamilyName]/[memberCount]/[barangayName]
/// are the only fields the Pending Registrations *list* screen reads,
/// specifically so that screen never has to parse or display the full
/// payload just to render a row.
class PendingFamilyRegistrationModel {
  PendingFamilyRegistrationModel({
    required this.id,
    required this.localId,
    required this.createdAtEpochMs,
    required this.updatedAtEpochMs,
    required this.syncStatus,
    this.attemptCount = 0,
    this.lastAttemptAtEpochMs,
    this.lastErrorCategory,
    this.lastErrorMessage,
    this.fieldErrorsJson,
    required this.payloadJson,
    required this.headOfFamilyName,
    required this.memberCount,
    required this.barangayName,
    this.ownerStaffId,
  });

  /// Derived deterministically from [localId] via [fastHash] — a
  /// stable, deterministic id for the in-memory model, even though the
  /// Drift table itself keys on the real [localId] directly.
  final int id;

  /// A client-generated UUID (v4), stable for the lifetime of this
  /// registration record regardless of sync attempts — used for
  /// navigation (`/settings/staff/pending-registrations/:localId`),
  /// as the value [id] is derived from, and as the real Drift primary
  /// key (`PendingFamilyRegistrations.localId`).
  final String localId;

  final int createdAtEpochMs;
  final int updatedAtEpochMs;

  /// One of: pending | syncing | needsAttention — see
  /// `PendingRegistrationStatus` in the domain layer for the typed
  /// version and `StaffSyncService` for the transitions between them.
  final String syncStatus;

  final int attemptCount;
  final int? lastAttemptAtEpochMs;

  /// One of: validation | authExpired | forbidden | ambiguous | server
  /// | offline — set only when [syncStatus] is needsAttention, so the
  /// Pending Registrations screen can show a specific reason rather
  /// than a generic "failed."
  final String? lastErrorCategory;
  final String? lastErrorMessage;

  /// JSON-encoded `Map<String, List<String>>` of backend 422 field
  /// errors (e.g. `"members.0.first_name"`), only set when
  /// [lastErrorCategory] is `validation` — lets the edit screen map
  /// each error back onto its field.
  final String? fieldErrorsJson;

  /// The exact `/families/register` request body, JSON-encoded. Never
  /// logged, never shown in list summaries — see class doc comment.
  final String payloadJson;

  final String headOfFamilyName;
  final int memberCount;
  final String barangayName;

  /// The authenticated staff user's real backend `id` (from
  /// `StaffSession.id`/`UserResource.id`) at the moment this record
  /// was queued — never the name or email, since those can change
  /// and aren't guaranteed unique the way the backend's numeric user
  /// id is. Used to scope every read/write in
  /// `PendingQueueRepositoryImpl` to "only this signed-in staff
  /// member's own queue," so one account can never see, sync, edit,
  /// or delete another's queued registrations on a shared device.
  ///
  /// Nullable only so records queued before this field existed can
  /// still be read (old rows decode this as null) — see
  /// `PendingQueueRepositoryImpl._claimLegacyRecordsIfNeeded`, which
  /// adopts them into whichever account next opens the queue on this
  /// device rather than losing or permanently orphaning them.
  final int? ownerStaffId;
}
