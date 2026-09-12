import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cache/offline_cache_service.dart';
import '../../../../core/sync/sync_timestamps.dart';
import '../../../alerts/presentation/providers/alerts_summary_provider.dart';
import '../../../evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import '../../../map/presentation/providers/map_provider.dart';

part 'offline_data_provider.g.dart';

/// Real, measured cache state — every field here comes straight from
/// [OfflineCacheService] (Isar's own `count()`/`getSize()`) and
/// [SyncTimestampService] (real fetch-success timestamps). Nothing is
/// estimated; a category with no cached rows just reports 0.
class OfflineDataSnapshot {
  const OfflineDataSnapshot({required this.stats, required this.syncedAt});

  final Map<CacheCategory, CacheCategoryStats> stats;
  final Map<SyncDomain, DateTime?> syncedAt;

  int get totalRecords => stats.values.fold(0, (sum, s) => sum + s.recordCount);

  int get totalSizeBytes => stats.values.fold(0, (sum, s) => sum + s.sizeBytes);

  /// The most recent successful sync across every domain, or null if
  /// nothing has ever synced on this device — used for the Settings
  /// screen's single "Sync Now" subtitle, which doesn't break freshness
  /// down per-domain the way Offline Data Management does.
  DateTime? get mostRecentSync {
    final values = syncedAt.values.whereType<DateTime>();
    return values.isEmpty
        ? null
        : values.reduce((a, b) => a.isAfter(b) ? a : b);
  }
}

/// Drives both the Settings screen's "Offline Data"/"Sync Now" rows and
/// the full Offline Data Management screen.
///
/// [build] is a plain read of current state — it doesn't itself fetch
/// anything from the network. [syncAll] and [clearCachedData] are the
/// two real actions: both drive the same three domain providers
/// (evacuation centers, alerts, map/hazards) that every other screen
/// already uses, via the identical invalidate-then-await pattern
/// `HomePage`'s pull-to-refresh uses — this provider doesn't duplicate
/// any fetch/cache/parsing logic, it only orchestrates providers that
/// already exist.
@riverpod
class OfflineDataOverview extends _$OfflineDataOverview {
  @override
  Future<OfflineDataSnapshot> build() async {
    final cacheService = ref.watch(offlineCacheServiceProvider);
    final syncService = ref.watch(syncTimestampServiceProvider);
    final stats = await cacheService.getStats();
    final syncedAt = await syncService.getAllSynced();
    return OfflineDataSnapshot(stats: stats, syncedAt: syncedAt);
  }

  /// Refreshes every cached domain. A domain whose request fails simply
  /// keeps its last-known-good cache — exactly what each repository's
  /// existing network-then-cache-fallback logic already guarantees, not
  /// something this method adds — and its sync timestamp just doesn't
  /// advance. Returns `false` if at least one domain failed, so the
  /// caller can show an honest partial-failure message rather than
  /// claiming full success.
  Future<bool> syncAll() async {
    ref.invalidate(allEvacuationCentersProvider);
    ref.invalidate(alertsSummaryProvider);
    ref.invalidate(alertsListProvider);
    ref.invalidate(mapDataProvider);

    final results = await Future.wait([
      _settle(ref.read(allEvacuationCentersProvider.future)),
      _settle(ref.read(alertsSummaryProvider.future)),
      _settle(ref.read(mapDataProvider.future)),
    ]);

    ref.invalidateSelf();
    await future;
    return results.every((ok) => ok);
  }

  static Future<bool> _settle(Future<Object?> future) async {
    try {
      await future;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Empties every Isar-cached domain and this device's sync-timestamp
  /// history, then re-invalidates every affected provider so no screen
  /// is left showing data that was just removed. Never touches the
  /// language preference or any other app setting — see
  /// [OfflineCacheService.clearAll] and [SyncTimestampService.clearAll],
  /// which only ever write to their own dedicated keys/collections.
  Future<void> clearCachedData() async {
    await ref.read(offlineCacheServiceProvider).clearAll();
    await ref.read(syncTimestampServiceProvider).clearAll();

    ref.invalidate(allEvacuationCentersProvider);
    ref.invalidate(alertsSummaryProvider);
    ref.invalidate(alertsListProvider);
    ref.invalidate(mapDataProvider);

    ref.invalidateSelf();
    await future;
  }
}
