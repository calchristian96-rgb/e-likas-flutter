import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/database/staff_database.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/staff_api_client.dart';
import '../../../staff_auth/presentation/providers/staff_auth_provider.dart';
import '../../data/datasources/registered_families_local_datasource.dart';
import '../../data/datasources/registered_families_remote_datasource.dart';
import '../../data/repositories/registered_families_repository_impl.dart';
import '../../data/services/registered_families_sync_timestamps.dart';
import '../../domain/entities/registered_family.dart';
import '../../domain/entities/registered_families_snapshot.dart';
import '../../domain/repositories/registered_families_repository.dart';

part 'registered_families_provider.g.dart';

/// Rebuilds — and re-scopes every provider below it — whenever the
/// signed-in staff account changes, same pattern as
/// `pendingQueueRepositoryProvider`.
@riverpod
RegisteredFamiliesRepository registeredFamiliesRepository(Ref ref) {
  final ownerStaffId = ref.watch(staffAuthProvider).value?.id;
  return RegisteredFamiliesRepositoryImpl(
    remote: RegisteredFamiliesRemoteDataSource(
      ref.watch(staffApiClientProvider),
    ),
    local: RegisteredFamiliesLocalDataSource(ref.watch(staffDatabaseProvider)),
    connectivity: ref.watch(connectivityServiceProvider),
    syncTimestamps: ref.watch(registeredFamiliesSyncTimestampServiceProvider),
    ownerStaffId: ownerStaffId,
  );
}

/// Online-first, cache-fallback registered-families list — re-run on
/// pull-to-refresh via `ref.invalidate(registeredFamiliesProvider)`.
@riverpod
Future<RegisteredFamiliesSnapshot> registeredFamilies(Ref ref) async {
  final result = await ref.watch(registeredFamiliesRepositoryProvider).getAll();
  return switch (result) {
    Success(:final value) => value,
    Failed(:final failure) => throw failure,
  };
}

/// One barangay's families, sorted for display — head-of-family name
/// alphabetically, "Unnamed family" (empty name) rows last since they
/// have nothing meaningful to sort by.
class RegisteredFamiliesGroup {
  const RegisteredFamiliesGroup({
    required this.barangayName,
    required this.families,
  });

  final String barangayName;
  final List<RegisteredFamily> families;
}

/// [registeredFamiliesProvider]'s families, grouped by barangay
/// (alphabetical) and sorted by head-of-family name (alphabetical)
/// within each group — the presentation-layer concern the repository
/// itself deliberately stays free of, so `getCachedOnly()` (used by
/// Phase 3 duplicate checking) can stay a plain flat list.
@riverpod
Future<List<RegisteredFamiliesGroup>> registeredFamiliesGrouped(Ref ref) async {
  final snapshot = await ref.watch(registeredFamiliesProvider.future);
  final byBarangay = <String, List<RegisteredFamily>>{};
  for (final family in snapshot.families) {
    final key = family.barangayName.isEmpty
        ? '\u{10FFFF}' // sorts last
        : family.barangayName;
    byBarangay.putIfAbsent(key, () => []).add(family);
  }

  final barangayNames = byBarangay.keys.toList()..sort();
  return [
    for (final key in barangayNames)
      RegisteredFamiliesGroup(
        barangayName: key == '\u{10FFFF}' ? '' : key,
        families: byBarangay[key]!
          ..sort((a, b) {
            final aEmpty = a.headOfFamilyName.isEmpty;
            final bEmpty = b.headOfFamilyName.isEmpty;
            if (aEmpty != bEmpty) return aEmpty ? 1 : -1;
            return a.headOfFamilyName.toLowerCase().compareTo(
              b.headOfFamilyName.toLowerCase(),
            );
          }),
      ),
  ];
}

/// Cache-only, no network — the single provider Phase 3's local
/// duplicate-name checking reads from, so typing in the registration
/// form never triggers a request. Empty (never an error) when nothing
/// is cached yet.
@riverpod
Future<List<RegisteredFamily>> registeredFamiliesCacheOnly(Ref ref) {
  return ref.watch(registeredFamiliesRepositoryProvider).getCachedOnly();
}
