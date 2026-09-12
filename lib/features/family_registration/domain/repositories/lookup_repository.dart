import '../../../../core/error/result.dart';
import '../entities/lookup_entities.dart';

/// Barangays / evacuation events / evacuation centers — the three
/// lookup tables the registration form's dropdowns are built from.
/// Network-first with a cache fallback, the same pattern every
/// resident repository already uses (e.g.
/// `AlertsRepositoryImpl.getAlerts`), just pointed at the staff Isar
/// database and the authenticated endpoints instead.
abstract class LookupRepository {
  Future<Result<List<Barangay>>> getBarangays();
  Future<Result<List<EvacuationEventLookup>>> getEvacuationEvents();
  Future<Result<List<EvacuationCenterLookup>>> getEvacuationCenters();

  /// Epoch-ms of the last successful refresh of each lookup, or null
  /// if never synced — lets the form show "Using saved evacuation
  /// events (synced 2h ago)" instead of implying live data while
  /// offline.
  Future<int?> lastSyncedAt(LookupDomain domain);
}

enum LookupDomain { barangays, evacuationEvents, evacuationCenters }
