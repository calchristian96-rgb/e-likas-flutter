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
  int get schemaVersion => 1;
}

@Riverpod(keepAlive: true)
StaffDatabase staffDatabase(Ref ref) {
  final db = StaffDatabase(ref.watch(secureTokenStorageProvider));
  ref.onDispose(db.close);
  return db;
}
