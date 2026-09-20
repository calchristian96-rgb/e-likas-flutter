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

/// One offline-queued (or being-synced) EC Information Board "Add
/// Evacuee" entry — mirrors `PendingFamilyRegistrations` at a smaller
/// scale (one evacuee's bracket/sex/household, not a full
/// registration). See `EcBoardEntryDraft`'s doc comment for why the
/// household reference is split into two nullable columns rather than
/// one.
@DataClassName('PendingEcBoardEntryRow')
class PendingEcBoardEntries extends Table {
  TextColumn get localId => text()();

  IntColumn get evacuationCenterId => integer()();
  IntColumn get evacuationEventId => integer()();

  /// 'male' | 'female'.
  TextColumn get sex => text()();

  /// One of the 7 `AgeBracket` wire values.
  TextColumn get ageBracket => text()();

  /// 'existing' | 'new' — see `HouseholdMode`.
  TextColumn get householdMode => text()();

  /// Set once this entry's household is a confirmed real
  /// `families.id` — either chosen directly from an already-synced
  /// family, or promoted from [existingFamilyLocalId] once that local
  /// registration itself syncs (see
  /// `EcBoardRepository.promoteHouseholdReference`).
  IntColumn get existingFamilyRemoteId => integer().nullable()();

  /// Set when the household was chosen from this device's own
  /// still-`pending` `PendingFamilyRegistrations.localId` — cleared
  /// once promoted to [existingFamilyRemoteId].
  TextColumn get existingFamilyLocalId => text().nullable()();

  TextColumn get newHouseholdHeadName => text().nullable()();
  IntColumn get newHouseholdBarangayId => integer().nullable()();

  /// Display-only cache of the chosen household's name — see
  /// `PendingEcBoardEntrySummary.householdLabel`'s doc comment.
  TextColumn get householdLabel => text()();

  /// One of: pending | syncing | needsAttention.
  TextColumn get syncStatus => text()();

  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  IntColumn get lastAttemptAtEpochMs => integer().nullable()();
  TextColumn get lastErrorCategory => text().nullable()();
  TextColumn get lastErrorMessage => text().nullable()();

  IntColumn get createdAtEpochMs => integer()();
  IntColumn get updatedAtEpochMs => integer()();

  IntColumn get ownerStaffId => integer().nullable()();

  @override
  Set<Column> get primaryKey => {localId};
}

/// This device's own not-yet-synced sectoral/4Ps edit — at most one row
/// per (center, event, owner), unlike [PendingEcBoardEntries]' many
/// discrete rows: `PUT .../quick-count` is one mutable aggregate, not
/// an appendable list, so a second local save before the first syncs
/// simply overwrites this row rather than adding another one (see
/// `EcBoardRepository.saveQuickCountEdit`'s doc comment). No legacy
/// data predates this table, so — unlike the older tables above —
/// [ownerStaffId] is required rather than nullable-for-migration.
@DataClassName('PendingQuickCountEditRow')
class PendingQuickCountEdits extends Table {
  IntColumn get evacuationCenterId => integer()();
  IntColumn get evacuationEventId => integer()();
  IntColumn get ownerStaffId => integer()();

  IntColumn get beneficiaries4ps => integer()();

  /// JSON-encoded `List<{sectoral_group, male_count, female_count}>` —
  /// always all 8 categories (see `SectoralGroupDraft`'s doc comment).
  /// Kept as one JSON blob rather than 16 separate columns, same
  /// reasoning as `PendingFamilyRegistrations.payloadJson`: this data
  /// only ever needs to round-trip whole, never queried column-by-column.
  TextColumn get sectoralGroupsJson => text()();

  /// One of: pending | syncing | needsAttention.
  TextColumn get syncStatus => text()();

  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  IntColumn get lastAttemptAtEpochMs => integer().nullable()();
  TextColumn get lastErrorCategory => text().nullable()();
  TextColumn get lastErrorMessage => text().nullable()();

  IntColumn get createdAtEpochMs => integer()();
  IntColumn get updatedAtEpochMs => integer()();

  @override
  Set<Column> get primaryKey => {
    evacuationCenterId,
    evacuationEventId,
    ownerStaffId,
  };
}

/// Local cache of the last successfully-fetched `GET .../quick-count`
/// response for one (center, event) — mirrors `CachedQuickCountCodec`.
/// Not owner-scoped, unlike [PendingQuickCountEdits]: this is a mirror
/// of shared server truth (what the "last known" figures actually
/// are), not one staff member's own unsynced draft, so every signed-in
/// account on this device sees the same cached snapshot — same
/// reasoning as [LookupBarangays]/[LookupEvacuationEvents] having no
/// owner column either.
@DataClassName('CachedQuickCountRow')
class CachedQuickCounts extends Table {
  IntColumn get evacuationCenterId => integer()();
  IntColumn get evacuationEventId => integer()();

  /// JSON-encoded [EcBoardQuickCount] — see `CachedQuickCountCodec`.
  TextColumn get dataJson => text()();

  IntColumn get cachedAtEpochMs => integer()();

  @override
  Set<Column> get primaryKey => {evacuationCenterId, evacuationEventId};
}
