import 'package:drift/drift.dart';

/// Offline cache of `GET /barangays` — mirrors `LookupBarangayModel`.
@DataClassName('LookupBarangayRow')
class LookupBarangays extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Offline cache of `GET /evacuation-events` — mirrors
/// `LookupEvacuationEventModel`.
@DataClassName('LookupEvacuationEventRow')
class LookupEvacuationEvents extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get status => text()();
  TextColumn get startDate => text().nullable()();
  TextColumn get endDate => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Offline cache of the staff `GET /evacuation-centers` list (the
/// deliberately minimal id/name/barangayId/status shape the
/// registration form's "inside a center" picker needs) — mirrors
/// `LookupEvacuationCenterModel`.
@DataClassName('LookupEvacuationCenterRow')
class LookupEvacuationCenters extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  IntColumn get barangayId => integer()();
  TextColumn get status => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cache of `GET /families` rows, scoped per signed-in staff account —
/// mirrors `CachedFamilyModel`. Uses a composite (familyId, ownerStaffId)
/// primary key directly rather than `CachedFamilyModel`'s derived
/// `fastHash('$ownerStaffId:$familyId')` int id — Drift has no Isar-style
/// restriction forcing a single non-nullable int `Id` field, so the two
/// real identity columns can just be the primary key together.
/// `memberNames` (a `List<String>` on the Isar side, needed for local
/// duplicate-name checking and record inspection) is stored as a
/// newline-joined string — no member name can itself legitimately
/// contain a newline.
@DataClassName('CachedFamilyRow')
class CachedFamilies extends Table {
  IntColumn get familyId => integer()();
  IntColumn get ownerStaffId => integer()();
  IntColumn get barangayId => integer().nullable()();
  TextColumn get barangayName => text()();
  TextColumn get headOfFamilyName => text()();
  TextColumn get homeAddress => text().nullable()();
  IntColumn get memberCount => integer()();
  TextColumn get evacuationCenterName => text().nullable()();
  BoolColumn get is4psBeneficiary =>
      boolean().withDefault(const Constant(false))();
  IntColumn get createdAtEpochMs => integer().nullable()();
  TextColumn get memberNamesNewlineJoined =>
      text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {familyId, ownerStaffId};
}

/// One offline-queued (or being-synced) family registration — mirrors
/// `PendingFamilyRegistrationModel`, the single highest-risk dataset in
/// this whole migration (see the migration bridge's own doc comment).
///
/// [localId] (a client-generated UUID) is the primary key directly —
/// unlike the Isar collection, which had to derive a synthetic int id
/// from it (`fastHash(localId)`) because Isar rejects a nullable `Id`
/// field and this version has no working auto-increment. Drift places
/// no such restriction on primary-key types, so the real stable
/// identifier can just be the key.
@DataClassName('PendingFamilyRegistrationRow')
class PendingFamilyRegistrations extends Table {
  TextColumn get localId => text()();

  IntColumn get createdAtEpochMs => integer()();
  IntColumn get updatedAtEpochMs => integer()();

  /// One of: pending | syncing | needsAttention — see
  /// `PendingRegistrationStatus` in the domain layer.
  TextColumn get syncStatus => text()();

  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  IntColumn get lastAttemptAtEpochMs => integer().nullable()();

  /// One of: validation | authExpired | forbidden | ambiguous | server
  /// | offline — set only when [syncStatus] is needsAttention.
  TextColumn get lastErrorCategory => text().nullable()();
  TextColumn get lastErrorMessage => text().nullable()();

  /// JSON-encoded `Map<String, List<String>>` of backend 422 field
  /// errors, only set when [lastErrorCategory] is `validation`.
  TextColumn get fieldErrorsJson => text().nullable()();

  /// The exact `/families/register` request body, JSON-encoded. Never
  /// logged, never shown in list summaries. This is the one column in
  /// the whole app carrying full member PII (names, DOB, contact
  /// numbers, sectoral flags) — held only in this encrypted database.
  TextColumn get payloadJson => text()();

  TextColumn get headOfFamilyName => text()();
  IntColumn get memberCount => integer()();
  TextColumn get barangayName => text()();

  /// The authenticated staff user's real backend `id` at the moment
  /// this record was queued — see `PendingFamilyRegistrationModel
  /// .ownerStaffId`'s doc comment for the full reasoning (nullable
  /// only for legacy records queued before this field existed).
  IntColumn get ownerStaffId => integer().nullable()();

  @override
  Set<Column> get primaryKey => {localId};
}
