import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'sync_timestamps.g.dart';

/// The data domains the Settings/Offline Data Management screens report
/// freshness for — one per repository that maintains its own Isar
/// cache. Deliberately not "nearestCenter": nearest-center results are
/// cached into the same [EvacuationCenterModel] collection
/// [evacuationCenters] already covers, so a separate timestamp for it
/// would just duplicate this one.
enum SyncDomain { alerts, evacuationCenters, hazardMap }

const _keyPrefix = 'elikas.sync.';

/// Real "last successfully cached fresh data" timestamps, one per
/// [SyncDomain] — backed by [SharedPreferences], the same lightweight
/// mechanism already used for the language preference. Deliberately
/// separate from that key (`elikas.locale`) so clearing sync timestamps
/// (see [clearAll]) can never touch it.
///
/// Written only from inside each repository's network-success path
/// (see e.g. [AlertsRepositoryImpl.getAlerts]) — that's the one place
/// in the app that actually knows fresh data was just fetched and
/// cached, as opposed to a `Success` served from the offline cache
/// fallback. Providers alone can't tell those two cases apart, since
/// [Result] doesn't carry that distinction.
class SyncTimestampService {
  Future<void> markSynced(SyncDomain domain) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '$_keyPrefix${domain.name}',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<DateTime?> getSynced(SyncDomain domain) async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('$_keyPrefix${domain.name}');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<Map<SyncDomain, DateTime?>> getAllSynced() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final domain in SyncDomain.values)
        domain: switch (prefs.getInt('$_keyPrefix${domain.name}')) {
          null => null,
          final ms => DateTime.fromMillisecondsSinceEpoch(ms),
        },
    };
  }

  /// Removes only the `elikas.sync.*` keys this service owns — never
  /// touches `elikas.locale` (see [AppLocale]) or any other preference,
  /// even though they share the same [SharedPreferences] store. Called
  /// alongside [OfflineCacheService.clearAll] so a "Clear Cached Data"
  /// action can't leave a stale "Updated 2 hours ago" caption pointing
  /// at data that no longer exists.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final domain in SyncDomain.values) {
      await prefs.remove('$_keyPrefix${domain.name}');
    }
  }
}

@riverpod
SyncTimestampService syncTimestampService(Ref ref) => SyncTimestampService();
