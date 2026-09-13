import '../../../../core/error/result.dart';
import '../entities/center_facility.dart';
import '../entities/evacuation_center.dart';

/// Contract the data layer implements. Domain and presentation depend
/// on this abstraction only — never on Dio or Isar directly.
abstract class EvacuationCentersRepository {
  /// All evacuation centers, network-first with cache fallback.
  Future<Result<List<EvacuationCenter>>> getAllCenters();

  /// One center's facilities checklist, live only — no offline cache,
  /// unlike [getAllCenters]/[getNearestCenters]. Used solely by the
  /// details page's independent Facilities section, which must never
  /// block or fail the rest of the page (see the presentation layer).
  Future<Result<List<CenterFacility>>> getCenterFacilities(int centerId);

  /// Centers nearest to [latitude]/[longitude], network-first.
  ///
  /// If the network call fails and [allowOfflineFallback] is true,
  /// falls back to ranking the last cached full list client-side by
  /// straight-line distance instead of failing outright — same UX for
  /// the resident, no new endpoint involved.
  Future<Result<List<EvacuationCenter>>> getNearestCenters({
    required double latitude,
    required double longitude,
    int limit = 10,
    bool allowOfflineFallback = true,
  });

  /// Best-effort backfill: if [centerId]'s cached row has no photo yet,
  /// fetches the real one from `GET public/evacuation-centers/{id}`
  /// (the only resident-reachable endpoint besides GIS map data that
  /// returns `photo_url` — the plain list never does) and caches it.
  /// Never throws; returns true only when a new photo was actually
  /// written to the cache, so the caller knows whether a refresh of
  /// the centers list is worthwhile.
  Future<bool> refreshCenterPhotoIfMissing(int centerId);
}
