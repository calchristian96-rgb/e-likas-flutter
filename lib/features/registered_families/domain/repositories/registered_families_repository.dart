import '../../../../core/error/result.dart';
import '../entities/registered_family.dart';
import '../entities/registered_families_snapshot.dart';

/// Online-first, cache-fallback access to the authenticated
/// `GET /families` list — the barangay/role scoping in that response
/// is entirely server-side (see `FamilyController::index`); this
/// repository never applies its own barangay filter, it only ever
/// caches and re-serves whatever the backend already decided this
/// staff account may see.
abstract class RegisteredFamiliesRepository {
  /// Tries the network first; on success, replaces this account's
  /// entire cache with the fresh result. On failure (offline, timeout,
  /// server error), falls back to the cache; a [Failed] is only
  /// returned when *neither* a fresh fetch nor a cache exists yet.
  Future<Result<RegisteredFamiliesSnapshot>> getAll();

  /// Cache only, never touches the network — the one method local
  /// duplicate-name checking uses (Phase 3), so typing in the
  /// registration form never triggers a request. Returns an empty list
  /// (never throws) when nothing is cached yet or no session is
  /// resolved.
  Future<List<RegisteredFamily>> getCachedOnly();
}
