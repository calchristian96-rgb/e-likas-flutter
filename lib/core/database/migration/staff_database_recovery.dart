import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart' as sqlite3_open;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../../debug/pending_count_debug_log.dart';
import '../staff_database.dart';
import 'drift_migration_flags.dart';

enum _StaffDbClassification { currentKeyEncrypted, plaintext, unreadable }

/// Runs once, BEFORE the app's real `staffDatabaseProvider` connection
/// is ever handed a live query, to make sure the canonical
/// `elikas_staff.sqlite` file is actually openable with the current
/// SQLCipher key — see `db_connection.dart`'s call site for exactly
/// where this sits in the staff database's open sequence.
///
/// This exists because of a real-device failure: `SqliteException(26):
/// file is not a database` on `PRAGMA user_version` while opening the
/// staff database, discovered only after the earlier
/// `NativeDatabase.createInBackground` → same-isolate `NativeDatabase`
/// fix let Drift actually reach that point for the first time. Two
/// realistic causes exist for a file that fails to open with the
/// current key:
///  - The file is a genuinely valid SQLCipher database, just encrypted
///    under a DIFFERENT key than the one currently in secure storage
///    (e.g. if the device's Keystore-backed secure storage entry was
///    ever invalidated/reset independently of the database file — a
///    known Android footgun with `flutter_secure_storage`, and
///    something this app's own key-generation code can't detect on
///    its own since [SecureTokenStorage.readOrCreateDriftEncryptionKey]
///    just sees "no key" and mints a new one).
///  - The file is genuinely corrupt/truncated (e.g. a write was
///    interrupted).
/// A third, less likely possibility this class also checks for:
///  - The file is valid, *plaintext* SQLite (never encrypted) — not
///    reachable through this app's current code (`readOrCreateDrift
///    EncryptionKey` can't return null), but checked anyway since a
///    genuinely valid plaintext file, if one exists, deserves an
///    attempt to preserve its data rather than being discarded outright
///    the way an unrecoverable file is.
///
/// In every case, an unusable file is renamed to a timestamped backup
/// rather than deleted, and a successfully-classified/recovered file
/// is never touched further — this service only ever gets a file into
/// an openable state, never edits it beyond that.
///
/// Historical note: this originally treated the legacy staff Isar
/// database as an ultimate fallback (a classification bug here could
/// never cause data loss, since the Isar→Drift bridge could always
/// rebuild the Drift cache from Isar again). Now that Isar has been
/// fully removed (verified migrated and safe to remove — see
/// `DriftMigrationFlags`/each staff datasource's history), that
/// fallback no longer exists: an unreadable Drift file now means a
/// fresh, empty database for datasets that can be resynced from the
/// API, and (for pending registrations specifically) reliance on the
/// timestamped backup file this service preserves rather than deletes.
class StaffDatabaseRecoveryService {
  StaffDatabaseRecoveryService._();

  static const _dbFileName = 'elikas_staff.sqlite';
  static const _generationPrefsKey =
      'elikas.drift_migration.staff_db_generation';

  static final _staffOnlyDatasets = [
    DriftDataset.lookupBarangays,
    DriftDataset.lookupEvacuationEvents,
    DriftDataset.lookupEvacuationCenters,
    DriftDataset.cachedFamilies,
    DriftDataset.pendingFamilyRegistrations,
  ];

  static bool _sqlCipherOverrideApplied = false;

  /// Idempotent per-isolate — safe to call from both this service and
  /// `db_connection.dart`'s own open path; `open.overrideFor(...)` is a
  /// plain reassignment, not a one-shot registration.
  static Future<void> _ensureSqlCipherOverrideApplied() async {
    if (_sqlCipherOverrideApplied) return;
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    sqlite3_open.open.overrideFor(
      sqlite3_open.OperatingSystem.android,
      openCipherOnAndroid,
    );
    _sqlCipherOverrideApplied = true;
  }

  /// Classifies and, if necessary, recovers the canonical staff
  /// database file. Returns once the file at the canonical path is
  /// guaranteed openable with [encryptionKey] — either because it
  /// already was, or because this just made it so (rebuilding it fresh,
  /// or migrating a recovered plaintext copy into place).
  ///
  /// Never deletes anything — an unusable file is always renamed to a
  /// timestamped backup, never removed, per the task's explicit backup
  /// policy.
  static Future<void> ensureRecovered(String encryptionKey) async {
    await _ensureSqlCipherOverrideApplied();

    final documentsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(documentsDir.path, _dbFileName));

    if (!await dbFile.exists()) {
      pendingCountDebugLog(
        'StaffDB recovery: no existing file — fresh database, nothing to '
        'recover',
      );
      await _recordGeneration();
      return;
    }

    final length = await dbFile.length();
    if (length == 0) {
      pendingCountDebugLog(
        'StaffDB recovery: existing file is zero-length — treated as fresh',
      );
      await _recordGeneration();
      return;
    }

    pendingCountDebugLog(
      'StaffDB recovery: existing file found, sizeBytes=$length — '
      'classifying',
    );
    final classification = await _classify(dbFile, encryptionKey);
    pendingCountDebugLog('StaffDB recovery: classification=$classification');

    switch (classification) {
      case _StaffDbClassification.currentKeyEncrypted:
        // Usable as-is. A generation marker may not exist yet if this
        // file predates this recovery mechanism — recording one now
        // does not imply anything was wrong, and does NOT reset any
        // migration flag, since nothing here indicates the existing
        // Drift data is untrustworthy.
        await _recordGeneration();
        return;
      case _StaffDbClassification.plaintext:
        await _recoverFromPlaintext(dbFile, encryptionKey, documentsDir);
        return;
      case _StaffDbClassification.unreadable:
        await _rebuildFromUnreadable(dbFile, documentsDir);
        return;
    }
  }

  /// Tries the current key first, then a plaintext read, touching
  /// nothing on disk either way — two independent, disposable raw
  /// `sqlite3` connections, never the app's own long-lived Drift
  /// connection.
  static Future<_StaffDbClassification> _classify(
    File dbFile,
    String encryptionKey,
  ) async {
    if (_tryOpen(dbFile, encryptionKey: encryptionKey)) {
      return _StaffDbClassification.currentKeyEncrypted;
    }
    if (_tryOpen(dbFile, encryptionKey: null)) {
      return _StaffDbClassification.plaintext;
    }
    return _StaffDbClassification.unreadable;
  }

  static bool _tryOpen(File dbFile, {required String? encryptionKey}) {
    sqlite3.Database? db;
    try {
      db = sqlite3.sqlite3.open(dbFile.path);
      if (encryptionKey != null) {
        db.execute("PRAGMA key = '$encryptionKey';");
      }
      // The actual decrypt/parse attempt happens on this first real
      // page read, not on the PRAGMA key statement itself.
      db.select('PRAGMA user_version;');
      return true;
    } catch (_) {
      return false;
    } finally {
      db?.dispose();
    }
  }

  /// Step 6: preserve a genuinely valid plaintext file's data rather
  /// than discarding it — copies every table into a fresh encrypted
  /// database via Drift's own generated `toCompanion()` (both sides
  /// share the exact same schema), verifies per-table row counts (and,
  /// for pending registrations, every field on every row), then only
  /// after everything is closed does it touch the filesystem: rename
  /// the original to a backup name, then move the verified new file
  /// into the canonical path.
  static Future<void> _recoverFromPlaintext(
    File plaintextFile,
    String encryptionKey,
    Directory documentsDir,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempFile = File(
      p.join(documentsDir.path, 'elikas_staff.recovering.$timestamp.sqlite'),
    );

    final source = StaffDatabase.forExecutor(NativeDatabase(plaintextFile));
    final dest = StaffDatabase.forExecutor(
      NativeDatabase(
        tempFile,
        setup: (db) => db.execute("PRAGMA key = '$encryptionKey';"),
      ),
    );

    final flagsToReset = <DriftDataset>{};
    try {
      await _copyIfMismatch(
        dataset: DriftDataset.lookupBarangays,
        sourceRows: await source.select(source.lookupBarangays).get(),
        write: (rows) => dest.batch(
          (b) => b.insertAllOnConflictUpdate(
            dest.lookupBarangays,
            rows.map((r) => r.toCompanion(false)).toList(),
          ),
        ),
        destCount: () =>
            dest.select(dest.lookupBarangays).get().then((r) => r.length),
        flagsToReset: flagsToReset,
      );
      await _copyIfMismatch(
        dataset: DriftDataset.lookupEvacuationEvents,
        sourceRows: await source.select(source.lookupEvacuationEvents).get(),
        write: (rows) => dest.batch(
          (b) => b.insertAllOnConflictUpdate(
            dest.lookupEvacuationEvents,
            rows.map((r) => r.toCompanion(false)).toList(),
          ),
        ),
        destCount: () => dest
            .select(dest.lookupEvacuationEvents)
            .get()
            .then((r) => r.length),
        flagsToReset: flagsToReset,
      );
      await _copyIfMismatch(
        dataset: DriftDataset.lookupEvacuationCenters,
        sourceRows: await source.select(source.lookupEvacuationCenters).get(),
        write: (rows) => dest.batch(
          (b) => b.insertAllOnConflictUpdate(
            dest.lookupEvacuationCenters,
            rows.map((r) => r.toCompanion(false)).toList(),
          ),
        ),
        destCount: () => dest
            .select(dest.lookupEvacuationCenters)
            .get()
            .then((r) => r.length),
        flagsToReset: flagsToReset,
      );
      await _copyIfMismatch(
        dataset: DriftDataset.cachedFamilies,
        sourceRows: await source.select(source.cachedFamilies).get(),
        write: (rows) => dest.batch(
          (b) => b.insertAllOnConflictUpdate(
            dest.cachedFamilies,
            rows.map((r) => r.toCompanion(false)).toList(),
          ),
        ),
        destCount: () =>
            dest.select(dest.cachedFamilies).get().then((r) => r.length),
        flagsToReset: flagsToReset,
      );
      await _copyPendingRegistrations(source, dest, flagsToReset);
    } finally {
      await source.close();
      await dest.close();
    }

    final backupFile = File(
      p.join(documentsDir.path, 'elikas_staff.pre_recovery.$timestamp.sqlite'),
    );
    await plaintextFile.rename(backupFile.path);
    await tempFile.rename(plaintextFile.path);

    for (final dataset in flagsToReset) {
      pendingCountDebugLog(
        'StaffDB recovery: resetting flag for $dataset (copy unverified)',
      );
    }
    // Datasets NOT in flagsToReset copied and verified successfully —
    // their existing "done" flag (if any) stays valid, since the data
    // it refers to now genuinely lives in the recovered file. Datasets
    // that failed verification get no flag reset here beyond adding
    // them to flagsToReset; the actual reset happens once, after the
    // file swap, via [_resetFlags].
    await _resetFlags(flagsToReset);
    await _recordGeneration();
    pendingCountDebugLog(
      'StaffDB recovery: plaintext recovery complete, '
      'resetFlagCount=${flagsToReset.length}',
    );
  }

  /// Copies one table's rows from [sourceRows] via [write] into the
  /// destination database, then confirms the destination's own count
  /// is at least as large as what was just copied. On any failure
  /// (write throws, or the count comes up short), [dataset] is added
  /// to [flagsToReset] rather than trusting the copy — the original
  /// plaintext file is preserved as a timestamped backup either way
  /// (never deleted), so a mismatched copy is surfaced via the debug
  /// log rather than silently accepted.
  static Future<void> _copyIfMismatch<T>({
    required DriftDataset dataset,
    required List<T> sourceRows,
    required Future<void> Function(List<T> rows) write,
    required Future<int> Function() destCount,
    required Set<DriftDataset> flagsToReset,
  }) async {
    try {
      if (sourceRows.isNotEmpty) {
        await write(sourceRows);
      }
      final count = await destCount();
      if (count < sourceRows.length) {
        pendingCountDebugLog(
          'StaffDB recovery: $dataset count mismatch '
          '(source=${sourceRows.length} dest=$count)',
        );
        flagsToReset.add(dataset);
      } else {
        pendingCountDebugLog(
          'StaffDB recovery: $dataset copied ok count=$count',
        );
      }
    } catch (error) {
      pendingCountDebugLog(
        'StaffDB recovery: $dataset copy failed error=${error.runtimeType}',
      );
      flagsToReset.add(dataset);
    }
  }

  /// Same idea as [_copyTable], but with the per-record field
  /// verification Step 9 requires for pending registrations
  /// specifically — a count match alone isn't enough for the one
  /// dataset holding irreplaceable unsynced user data.
  static Future<void> _copyPendingRegistrations(
    StaffDatabase source,
    StaffDatabase dest,
    Set<DriftDataset> flagsToReset,
  ) async {
    const dataset = DriftDataset.pendingFamilyRegistrations;
    try {
      final rows = await source.select(source.pendingFamilyRegistrations).get();
      if (rows.isNotEmpty) {
        await dest.batch((batch) {
          batch.insertAllOnConflictUpdate(
            dest.pendingFamilyRegistrations,
            rows.map((r) => r.toCompanion(false)).toList(),
          );
        });
      }

      var allVerified = true;
      for (final row in rows) {
        final copied = await (dest.select(
          dest.pendingFamilyRegistrations,
        )..where((t) => t.localId.equals(row.localId))).getSingleOrNull();
        if (copied == null ||
            copied.ownerStaffId != row.ownerStaffId ||
            copied.payloadJson != row.payloadJson ||
            copied.syncStatus != row.syncStatus ||
            copied.createdAtEpochMs != row.createdAtEpochMs ||
            copied.updatedAtEpochMs != row.updatedAtEpochMs ||
            copied.attemptCount != row.attemptCount ||
            copied.lastErrorCategory != row.lastErrorCategory ||
            copied.lastErrorMessage != row.lastErrorMessage ||
            copied.headOfFamilyName != row.headOfFamilyName ||
            copied.barangayName != row.barangayName) {
          allVerified = false;
          break;
        }
      }

      if (!allVerified) {
        pendingCountDebugLog(
          'StaffDB recovery: pending registration per-record verification '
          'FAILED — original file preserved as backup, resetting flag',
        );
        flagsToReset.add(dataset);
      } else {
        pendingCountDebugLog(
          'StaffDB recovery: pending registrations verified '
          'count=${rows.length}',
        );
      }
    } catch (error) {
      pendingCountDebugLog(
        'StaffDB recovery: pending registration copy failed '
        'error=${error.runtimeType}',
      );
      flagsToReset.add(dataset);
    }
  }

  /// Step 7: the file cannot be read at all, with the current key or
  /// as plaintext. There is nothing to salvage from a file that cannot
  /// even be opened — the safe action is to get it out of the way
  /// (rename to a timestamped backup, never delete) and start fresh
  /// with a brand-new file. Datasets backed by the API (alerts,
  /// centers, lookups) simply resync; pending registrations have no
  /// such fallback, which is why this only ever renames the
  /// unreadable file rather than discarding it.
  static Future<void> _rebuildFromUnreadable(
    File unreadableFile,
    Directory documentsDir,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupFile = File(
      p.join(documentsDir.path, 'elikas_staff.unreadable.$timestamp.sqlite'),
    );
    await unreadableFile.rename(backupFile.path);
    pendingCountDebugLog(
      'StaffDB recovery: unreadable file backed up to '
      '${backupFile.path.split(Platform.pathSeparator).last}',
    );

    await _resetFlags(_staffOnlyDatasets.toSet());
    await _recordGeneration();
    pendingCountDebugLog(
      'StaffDB recovery: rebuild scheduled — all staff migration flags '
      'reset, resident flags untouched',
    );
  }

  static Future<void> _resetFlags(Set<DriftDataset> datasets) async {
    for (final dataset in datasets) {
      await DriftMigrationFlags.reset(dataset);
    }
  }

  static Future<void> _recordGeneration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _generationPrefsKey,
      DateTime.now().microsecondsSinceEpoch.toString(),
    );
  }
}
