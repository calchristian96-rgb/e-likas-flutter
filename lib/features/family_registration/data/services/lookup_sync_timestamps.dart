import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/lookup_repository.dart';

part 'lookup_sync_timestamps.g.dart';

const _keyPrefix = 'elikas.staff.sync.';

/// Last-successful-refresh timestamps for the three staff lookup
/// caches — the same [SharedPreferences]-backed pattern as the
/// resident `SyncTimestampService` (core/sync/sync_timestamps.dart),
/// but deliberately a separate service with its own key prefix rather
/// than adding staff domains to that one's `SyncDomain` enum: that
/// enum drives the resident Settings → Offline Data Management list,
/// and staff lookup freshness has no business appearing there.
class LookupSyncTimestampService {
  Future<void> markSynced(LookupDomain domain) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '$_keyPrefix${domain.name}',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<int?> getSyncedEpochMs(LookupDomain domain) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyPrefix${domain.name}');
  }
}

@riverpod
LookupSyncTimestampService lookupSyncTimestampService(Ref ref) =>
    LookupSyncTimestampService();
