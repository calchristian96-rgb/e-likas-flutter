import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/database/resident_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/sync/sync_timestamps.dart';
import '../data/barangay_status_repository.dart';
import '../domain/barangay_status.dart';

final barangayStatusRepositoryProvider = Provider<BarangayStatusRepository>(
  (ref) => BarangayStatusRepository(
    ref.watch(apiClientProvider),
    ref.watch(residentDatabaseProvider),
    ref.watch(connectivityServiceProvider),
    ref.watch(syncTimestampServiceProvider),
  ),
);

/// Every barangay's public status (and the barangay list the resident
/// picks from). Refresh with `ref.invalidate`.
final barangayStatusBoardProvider = FutureProvider<BarangayStatusBoard>(
  (ref) => ref.watch(barangayStatusRepositoryProvider).getBoard(),
);

/// The barangay the resident lives in, chosen once on this device and
/// matched by id everywhere (centers carry `barangay_id`).
class ResidentBarangay {
  const ResidentBarangay({required this.id, required this.name});

  final int id;
  final String name;
}

const _idKey = 'elikas.residentBarangay.id';
const _nameKey = 'elikas.residentBarangay.name';

class ResidentBarangayNotifier extends Notifier<ResidentBarangay?> {
  @override
  ResidentBarangay? build() => null;

  /// Called once during splash, like the language and theme.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt(_idKey);
      final name = prefs.getString(_nameKey);
      if (id != null && name != null) {
        state = ResidentBarangay(id: id, name: name);
      }
    } catch (_) {
      // Unreadable preferences: the resident is simply asked again.
    }
  }

  Future<void> choose(BarangayStatus barangay) async {
    state = ResidentBarangay(id: barangay.id, name: barangay.name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_idKey, barangay.id);
    await prefs.setString(_nameKey, barangay.name);
  }
}

final residentBarangayProvider =
    NotifierProvider<ResidentBarangayNotifier, ResidentBarangay?>(
      ResidentBarangayNotifier.new,
    );

/// The resident's own barangay's status, or null when no barangay is
/// chosen or nothing is known yet.
final ownBarangayStatusProvider = Provider<AsyncValue<BarangayStatus?>>((ref) {
  final own = ref.watch(residentBarangayProvider);
  return ref
      .watch(barangayStatusBoardProvider)
      .whenData((board) => board.byId(own?.id));
});
