import 'package:shared_preferences/shared_preferences.dart';

/// Tracks, per dataset, whether that dataset's one-time Isar→Drift copy
/// has completed and been verified — see each local datasource's own
/// `_ensureMigrated`-style method for how this gates reads/writes.
///
/// Deliberately one flag per dataset rather than one flag for the whole
/// migration: a dataset is only ever marked done after its own
/// row-count (and, for pending registrations, per-record) verification
/// passes, so a device that gets killed mid-migration resumes on next
/// launch by re-running only the datasets that never got marked done —
/// already-verified datasets aren't re-copied.
enum DriftDataset {
  alerts,
  hazardAreas,
  evacuationCenters,
  lookupBarangays,
  lookupEvacuationEvents,
  lookupEvacuationCenters,
  cachedFamilies,
  pendingFamilyRegistrations,
}

/// Static-method utility, not an injected service — matches this
/// project's existing `SyncTimestampService` convention of calling
/// `SharedPreferences.getInstance()` directly at each call site rather
/// than threading a `SharedPreferences` instance through the
/// constructor (the plugin caches its own singleton internally, so
/// repeated calls are cheap).
class DriftMigrationFlags {
  DriftMigrationFlags._();

  static String _key(DriftDataset dataset) =>
      'elikas.drift_migration.${dataset.name}.v1_done';

  /// A second, deliberately distinct flag from [_key] — see
  /// [markLegacySourceUnreadable]'s doc comment for why "the legacy
  /// Isar source could not be opened, so this dataset is proceeding
  /// on Drift alone" must never be confused with "verified, complete."
  static String _unreadableKey(DriftDataset dataset) =>
      'elikas.drift_migration.${dataset.name}.v1_legacy_source_unreadable';

  static Future<bool> isDone(DriftDataset dataset) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(dataset)) ?? false;
  }

  static Future<void> markDone(DriftDataset dataset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(dataset), true);
  }

  /// Clears a dataset's flag — used only by
  /// `StaffDatabaseRecoveryService` when the Drift file backing that
  /// dataset had to be rebuilt/replaced, so a "done" flag can never
  /// permanently outlive the physical database it was verified
  /// against. The dataset's own `_ensureMigrated()` safely re-runs the
  /// normal Isar→Drift bridge the next time it's touched.
  static Future<void> reset(DriftDataset dataset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(dataset));
    await prefs.remove(_unreadableKey(dataset));
  }

  /// Records that this dataset's one-time Isar→Drift bridge could not
  /// even read its legacy Isar source (e.g. `EncryptionError` on a real
  /// device — the source file itself would not open) — deliberately
  /// **not** the same as [markDone]. `isDone` means "every legacy row
  /// was copied and verified"; this means "no legacy rows could be
  /// read at all, so this dataset is operating on whatever Drift
  /// already has (possibly nothing) until the legacy source becomes
  /// readable again or is superseded." A caller must never treat this
  /// as proof the legacy data was empty or successfully migrated.
  static Future<void> markLegacySourceUnreadable(DriftDataset dataset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_unreadableKey(dataset), true);
  }

  static Future<bool> isLegacySourceUnreadable(DriftDataset dataset) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_unreadableKey(dataset)) ?? false;
  }

  /// What every `_ensureMigrated()` should actually check before
  /// attempting another legacy-Isar read: either outcome means "don't
  /// retry the bridge for this dataset again," but callers that care
  /// about the difference (e.g. a future UI affordance surfacing
  /// "some offline data could not be verified") can still ask
  /// [isLegacySourceUnreadable] separately.
  static Future<bool> shouldSkipBridge(DriftDataset dataset) async {
    return await isDone(dataset) || await isLegacySourceUnreadable(dataset);
  }
}
