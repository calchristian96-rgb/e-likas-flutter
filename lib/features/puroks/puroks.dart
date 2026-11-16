import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../core/database/staff_database.dart';
import '../../core/network/staff_api_client.dart';

/// A zone within a barangay (backend step 6).
class Purok {
  const Purok({required this.id, required this.barangayId, required this.name});

  final int id;
  final int barangayId;
  final String name;
}

/// `GET /puroks?barangay_id=`, network first, then the copy on this
/// device, so quick add can offer the purok offline.
class PuroksRepository {
  PuroksRepository(this._api, this._db, this._connectivity);

  final StaffApiClient _api;
  final StaffDatabase _db;
  final ConnectivityService _connectivity;

  Future<List<Purok>> forBarangay(int barangayId) async {
    if (await _connectivity.hasConnection) {
      try {
        final response = await _api.get(
          '/puroks',
          queryParameters: {'barangay_id': barangayId},
        );
        final rows = [
          for (final p
              in (response.data as Map<String, dynamic>)['data'] as List)
            Purok(
              id: (p as Map<String, dynamic>)['id'] as int,
              barangayId: barangayId,
              name: p['name'] as String,
            ),
        ];
        await _db.transaction(() async {
          await (_db.delete(
            _db.lookupPuroks,
          )..where((t) => t.barangayId.equals(barangayId))).go();
          await _db.batch(
            (b) => b.insertAll(_db.lookupPuroks, [
              for (final p in rows)
                LookupPuroksCompanion.insert(
                  id: Value(p.id),
                  barangayId: p.barangayId,
                  name: p.name,
                ),
            ]),
          );
        });
        return rows;
      } catch (_) {
        // Fall back to the saved copy.
      }
    }
    final saved =
        await (_db.select(_db.lookupPuroks)
              ..where((t) => t.barangayId.equals(barangayId))
              ..orderBy([(t) => OrderingTerm(expression: t.name)]))
            .get();
    return [
      for (final r in saved)
        Purok(id: r.id, barangayId: r.barangayId, name: r.name),
    ];
  }
}

final puroksRepositoryProvider = Provider<PuroksRepository>(
  (ref) => PuroksRepository(
    ref.watch(staffApiClientProvider),
    ref.watch(staffDatabaseProvider),
    ref.watch(connectivityServiceProvider),
  ),
);

/// A barangay's puroks, by name; empty when it has none or none are
/// known on this device yet (the purok is optional everywhere).
final puroksForBarangayProvider = FutureProvider.autoDispose
    .family<List<Purok>, int>(
      (ref, barangayId) =>
          ref.watch(puroksRepositoryProvider).forBarangay(barangayId),
    );
