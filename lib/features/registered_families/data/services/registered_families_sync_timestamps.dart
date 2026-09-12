import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'registered_families_sync_timestamps.g.dart';

const _keyPrefix = 'elikas.staff.families.sync.';

/// Last-successful-fetch timestamp for the registered-families cache,
/// per staff account — same [SharedPreferences]-backed pattern as
/// `LookupSyncTimestampService`, but keyed by [ownerStaffId] since
/// (unlike the shared lookup caches) this data is account-scoped:
/// switching staff accounts on the same device must not show one
/// account's freshness timestamp for another account's cache.
class RegisteredFamiliesSyncTimestampService {
  Future<void> markSynced(int ownerStaffId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '$_keyPrefix$ownerStaffId',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<int?> getSyncedEpochMs(int ownerStaffId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyPrefix$ownerStaffId');
  }
}

@riverpod
RegisteredFamiliesSyncTimestampService registeredFamiliesSyncTimestampService(
  Ref ref,
) => RegisteredFamiliesSyncTimestampService();
