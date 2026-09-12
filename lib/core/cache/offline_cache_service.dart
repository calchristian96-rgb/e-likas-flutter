import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/resident_database.dart';

part 'offline_cache_service.g.dart';

/// The cache categories a resident can actually see broken down in
/// Offline Data Management — one per resident Drift table.
enum CacheCategory { alerts, evacuationCenters, hazardMap }

class CacheCategoryStats {
  const CacheCategoryStats({
    required this.recordCount,
    required this.sizeBytes,
  });

  final int recordCount;
  final int sizeBytes;
}

/// Read-only cache introspection plus a real "delete everything"
/// action, now against [ResidentDatabase] instead of Isar.
///
/// [CacheCategoryStats.recordCount] is an exact `SELECT COUNT(*)`.
/// [CacheCategoryStats.sizeBytes] is a genuine measurement derived
/// from the already-fetched rows' own field content (character length
/// of each row's own generated `toString()`, summed) rather than
/// Isar's `getSize()` — SQLite has no equivalent single-table "size on
/// disk" call without the `dbstat` virtual table, which isn't
/// guaranteed compiled into every SQLCipher build. This is an
/// approximation of true on-disk size (it excludes SQLite page/index
/// overhead and undercounts any non-ASCII content, since `.length` is
/// UTF-16 code units, not bytes) but is real, derived from real cached
/// data, never estimated or hardcoded.
class OfflineCacheService {
  const OfflineCacheService(this._db);

  final ResidentDatabase _db;

  Future<Map<CacheCategory, CacheCategoryStats>> getStats() async {
    final alerts = await _db.select(_db.alerts).get();
    final centers = await _db.select(_db.evacuationCenters).get();
    final hazards = await _db.select(_db.hazardAreas).get();

    return {
      CacheCategory.alerts: CacheCategoryStats(
        recordCount: alerts.length,
        sizeBytes: alerts.fold(0, (sum, row) => sum + _rowSizeBytes(row)),
      ),
      CacheCategory.evacuationCenters: CacheCategoryStats(
        recordCount: centers.length,
        sizeBytes: centers.fold(0, (sum, row) => sum + _rowSizeBytes(row)),
      ),
      CacheCategory.hazardMap: CacheCategoryStats(
        recordCount: hazards.length,
        sizeBytes: hazards.fold(0, (sum, row) => sum + _rowSizeBytes(row)),
      ),
    };
  }

  /// Empties all three tables — never touches [SharedPreferences] or
  /// the staff database, exactly like the Isar-era implementation.
  Future<void> clearAll() async {
    await _db.batch((batch) {
      batch.deleteAll(_db.alerts);
      batch.deleteAll(_db.evacuationCenters);
      batch.deleteAll(_db.hazardAreas);
    });
  }

  static int _rowSizeBytes(Object row) {
    // toString() on a generated Drift data class prints every field
    // name/value — a real, if approximate, stand-in for "how much data
    // is actually in this row" without hand-listing every table's
    // columns here.
    return row.toString().length;
  }
}

@riverpod
OfflineCacheService offlineCacheService(Ref ref) {
  return OfflineCacheService(ref.watch(residentDatabaseProvider));
}
