import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart' as sqlite3_open;

import '../debug/pending_count_debug_log.dart';
import 'migration/staff_database_recovery.dart';

/// Opens a Drift [NativeDatabase] backed by SQLCipher's native SQLite
/// build — the single native SQLite provider for this whole app (see
/// the `sqlcipher_flutter_libs` note in pubspec.yaml for why it's this
/// package and not `sqlite3_flutter_libs`, even for the unencrypted
/// resident database).
///
/// [encryptionKeyProvider], if given, is resolved lazily inside the
/// same [LazyDatabase] callback that does everything else here — never
/// eagerly at call time — so that reading the key (an async
/// `flutter_secure_storage` call) doesn't force [openSqlCipherDatabase]
/// itself to be async. That keeps `StaffDatabase`'s own Riverpod
/// provider a plain synchronous one, matching the `StaffIsarService`
/// provider it replaces (which was sync for the exact same reason —
/// see that provider's own doc comment) and avoiding a ripple of every
/// staff repository provider in the app becoming `Future<...>` just to
/// thread an async key through. The resolved key is applied as
/// `PRAGMA key` immediately after opening and before any other
/// statement runs, per SQLCipher's own requirement that the key be set
/// before the database is touched. Passing null (or a provider that
/// resolves to null) opens a genuinely unencrypted database —
/// SQLCipher's build is a superset of plain SQLite, so a connection
/// with no key behaves exactly like ordinary SQLite (used for the
/// resident database, which holds nothing sensitive).
///
/// Deliberately the plain [NativeDatabase] constructor, **not**
/// [NativeDatabase.createInBackground] — this was the actual cause of
/// the real-device `Failed to load dynamic library .../libsqlite3.so`
/// crash. `createInBackground` spawns its own separate background
/// isolate to do the real SQLite work, and that is where its internal
/// `sqlite3.open()` call actually runs. `open.overrideFor(...)` below
/// only mutates `package:sqlite3`'s override table in *this* isolate —
/// isolates don't share static state — so the spawned isolate saw no
/// override at all and fell through to the unoverridden Android
/// default, which looks for a plain `libsqlite3.so` that was never
/// bundled (only SQLCipher's differently-named library was, reachable
/// solely through [openCipherOnAndroid]). Running everything —
/// the override, the `PRAGMA key`, and the actual `sqlite3.open()` —
/// on this single isolate, in this fixed order, is what guarantees the
/// override is visible when it matters. The tradeoff is that database
/// work now runs on the calling isolate (blocking it) instead of a
/// dedicated worker; acceptable here given this app's cache-sized,
/// low-throughput query volume.
QueryExecutor openSqlCipherDatabase(
  String fileName, {
  Future<String?> Function()? encryptionKeyProvider,
}) {
  final isStaffDb = fileName == 'elikas_staff.sqlite';
  return LazyDatabase(() async {
    if (isStaffDb) pendingCountDebugLog('StaffDatabase opening');
    try {
      await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
      sqlite3_open.open.overrideFor(
        sqlite3_open.OperatingSystem.android,
        openCipherOnAndroid,
      );

      final documentsDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(documentsDir.path, fileName));
      final encryptionKey = await encryptionKeyProvider?.call();

      if (isStaffDb && encryptionKey != null) {
        // Classifies/recovers the on-disk file BEFORE the connection
        // below is ever handed to the app — see
        // StaffDatabaseRecoveryService's own doc comment for exactly
        // why this exists (SqliteException(26) "file is not a
        // database" on a real device) and what it does.
        await StaffDatabaseRecoveryService.ensureRecovered(encryptionKey);
      }

      final database = NativeDatabase(
        file,
        setup: (database) {
          if (encryptionKey != null) {
            database.execute("PRAGMA key = '$encryptionKey';");
          }
        },
      );
      if (isStaffDb) pendingCountDebugLog('StaffDatabase opened');
      return database;
    } catch (error, stackTrace) {
      if (isStaffDb) {
        pendingCountDebugLog('DATABASE ERROR TYPE=${error.runtimeType}');
        pendingCountDebugLog('DATABASE ERROR=$error (StaffDatabase open)');
        pendingCountDebugLog('DATABASE STACK=$stackTrace');
      }
      rethrow;
    }
  });
}
