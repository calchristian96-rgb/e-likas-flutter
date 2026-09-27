import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../security/secure_token_storage.dart';
import 'db_connection.dart';
import 'tables/staff_tables.dart';

part 'staff_database.g.dart';

/// The Drift replacement for the staff (encrypted) Isar instance — see
/// `core/cache/staff_isar_service.dart`'s doc comment for the
/// collections this takes over. Opened with a real `PRAGMA key`
/// (SQLCipher encryption at rest) from a per-device random key stored
/// in `SecureTokenStorage`, matching the security posture of the Isar
/// instance it replaces exactly — this file holds real member PII
/// (`PendingFamilyRegistrations.payloadJson`) until it syncs to the
/// backend.
///
/// The key itself is read lazily, inside the connection's own
/// `LazyDatabase` callback (see `openSqlCipherDatabase`'s doc comment)
/// — so, like `StaffIsarService`, nothing on the resident startup path
/// ever touches secure storage or creates this database file, and a
/// device that never uses the staff feature never creates it at all.
@DriftDatabase(
  tables: [
    LookupBarangays,
    LookupEvacuationEvents,
    LookupEvacuationCenters,
    CachedFamilies,
    PendingFamilyRegistrations,
    PendingEcBoardEntries,
    CachedQuickCounts,
  ],
)
class StaffDatabase extends _$StaffDatabase {
  StaffDatabase(SecureTokenStorage tokenStorage)
    : super(
        openSqlCipherDatabase(
          'elikas_staff.sqlite',
          encryptionKeyProvider: tokenStorage.readOrCreateDriftEncryptionKey,
        ),
      );

  /// Points a `StaffDatabase` instance at an arbitrary, already-built
  /// [QueryExecutor] instead of the app's one canonical
  /// `elikas_staff.sqlite` file — used only by
  /// `StaffDatabaseRecoveryService` to open a *second*, temporary
  /// connection (the old file being classified, or a new temp file
  /// being built) side-by-side with whatever the app's real
  /// `staffDatabaseProvider` instance is doing, without the two ever
  /// being the same open connection.
  StaffDatabase.forExecutor(super.executor);

  @override
  int get schemaVersion => 6;

  /// Schema 2 adds `PendingEcBoardEntries` (EC Information Board's
  /// offline queue); schema 3 added a typed sectoral/4Ps edit queue,
  /// dropped again in schema 6; schema 4 adds `CachedQuickCounts` (the
  /// "last known" quick-count snapshot, so it's still genuinely
  /// available — not just an error — when EC Board is opened offline);
  /// schema 6 adds Add Evacuee's optional per-person sectoral flags and
  /// new-household head answers to `PendingEcBoardEntries` (all
  /// nullable, so already-queued entries read as "not recorded" / "not
  /// yet known"), adds `CachedFamilies.hasHeadLinked`/
  /// `isLegacyBulkEntry`, and drops `pending_quick_count_edits`: the
  /// server now counts every sectoral group live and stores nothing a
  /// typed edit sends, so a leftover draft there could never have
  /// reached the board anyway. (5 was only ever an in-development
  /// build with some of these columns, so columns are added only where
  /// missing and either version upgrades cleanly.)
  /// — a real device on an earlier schema already has a populated
  /// `elikas_staff.sqlite` (pending registrations, cached families),
  /// so this must stay an additive `onUpgrade`, never a fresh
  /// `onCreate` wipe.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(pendingEcBoardEntries);
      }
      if (from < 4) {
        await m.createTable(cachedQuickCounts);
      }
      if (from < 6) {
        await m.deleteTable('pending_quick_count_edits');
        await _addMissingColumns(m, cachedFamilies, [
          cachedFamilies.hasHeadLinked,
          cachedFamilies.isLegacyBulkEntry,
        ]);
        // A no-op for a device upgrading from < 2, whose createTable()
        // above already used the table's current definition.
        final t = pendingEcBoardEntries;
        await _addMissingColumns(m, t, [
          t.isPwd,
          t.isPregnant,
          t.isLactating,
          t.isSoloParent,
          t.isIndigenousPerson,
          t.isFourPsBeneficiary,
          t.headIsSelf,
          t.isSingleHeaded,
          t.headIsMinor,
          t.headSex,
        ]);
      }
    },
  );

  Future<void> _addMissingColumns(
    Migrator m,
    TableInfo table,
    List<GeneratedColumn> columns,
  ) async {
    final existing = {
      for (final row in await customSelect(
        'PRAGMA table_info(${table.actualTableName})',
      ).get())
        row.read<String>('name'),
    };
    // No such table at all: create it whole, with every current column.
    if (existing.isEmpty) {
      await m.createTable(table);
      return;
    }
    for (final column in columns) {
      if (!existing.contains(column.name)) {
        await m.addColumn(table, column);
      }
    }
  }
}

@Riverpod(keepAlive: true)
StaffDatabase staffDatabase(Ref ref) {
  final db = StaffDatabase(ref.watch(secureTokenStorageProvider));
  ref.onDispose(db.close);
  return db;
}
