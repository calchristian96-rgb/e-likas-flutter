import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/database/resident_database.dart';
import '../../../../core/debug/center_photo_debug_log.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/sync/sync_timestamps.dart';
import '../../data/datasources/evacuation_centers_local_datasource.dart';
import '../../data/datasources/evacuation_centers_remote_datasource.dart';
import '../../data/repositories/evacuation_centers_repository_impl.dart';
import '../../domain/entities/center_facility.dart';
import '../../domain/entities/evacuation_center.dart';
import '../../domain/repositories/evacuation_centers_repository.dart';
import '../../domain/usecases/get_all_evacuation_centers.dart';
import '../../domain/usecases/get_nearest_evacuation_centers.dart';

part 'evacuation_centers_provider.g.dart';

@riverpod
EvacuationCentersRepository evacuationCentersRepository(Ref ref) {
  return EvacuationCentersRepositoryImpl(
    remoteDatasource: EvacuationCentersRemoteDatasource(
      ref.watch(apiClientProvider),
    ),
    localDatasource: EvacuationCentersLocalDatasource(
      ref.watch(residentDatabaseProvider),
    ),
    connectivityService: ref.watch(connectivityServiceProvider),
    syncTimestampService: ref.watch(syncTimestampServiceProvider),
  );
}

/// The full centers list — drives the Centers tab.
@riverpod
Future<List<EvacuationCenter>> allEvacuationCenters(Ref ref) async {
  final repository = ref.watch(evacuationCentersRepositoryProvider);
  final result = await GetAllEvacuationCenters(repository).call();
  return switch (result) {
    Success(:final value) => value,
    Failed(:final failure) => throw failure,
  };
}

/// A single center for Center Details, found in the already-loaded
/// full list rather than a new per-id request — the full list is what
/// every entry point into this screen (the centers list, Nearest
/// Center's primary card and "other nearby centers" rows) already has
/// loaded, and every field except `photoUrl` is fully covered by it
/// (see [centerPhotoRefreshProvider] for how that one gap is closed).
/// Null means the list loaded fine but genuinely has no center with
/// this id — an unreachable case from in-app navigation, but a stale
/// deep link could reach it, so the page has to handle it rather than
/// assume.
@riverpod
Future<EvacuationCenter?> centerById(Ref ref, int id) async {
  final centers = await ref.watch(allEvacuationCentersProvider.future);
  for (final center in centers) {
    if (center.id == id) {
      centerPhotoDebugLog(
        'centerById id=$id (Center Details data source) photoUrl=${center.photoUrl}',
      );
      return center;
    }
  }
  centerPhotoDebugLog('centerById id=$id not found in allEvacuationCenters');
  return null;
}

/// Centers nearest to a given position — drives the nearest-center
/// screen once the resident's location is known.
///
/// Positional parameters rather than named ones: multi-parameter
/// family providers with named arguments are a newer riverpod_generator
/// feature that hasn't been independently confirmed against exactly
/// 4.0.3, while plain positional parameters are the longer-established,
/// more conservatively-supported pattern.
@riverpod
Future<List<EvacuationCenter>> nearestEvacuationCenters(
  Ref ref,
  double latitude,
  double longitude,
) async {
  final repository = ref.watch(evacuationCentersRepositoryProvider);
  final result = await GetNearestEvacuationCenters(
    repository,
  ).call(latitude: latitude, longitude: longitude);
  return switch (result) {
    Success(:final value) => value,
    Failed(:final failure) => throw failure,
  };
}

/// A single center's facilities checklist for the details page's
/// Facilities section — deliberately its own provider, independent
/// from [centerByIdProvider]/[allEvacuationCentersProvider], so a slow
/// or failed facilities request never affects the rest of Center
/// Details (see `CenterFacilitiesSection`).
@riverpod
Future<List<CenterFacility>> centerFacilities(Ref ref, int centerId) async {
  final repository = ref.watch(evacuationCentersRepositoryProvider);
  final result = await repository.getCenterFacilities(centerId);
  return switch (result) {
    Success(:final value) => value,
    Failed(:final failure) => throw failure,
  };
}

/// Silently backfills a real photo for [centerId] when its cached row
/// doesn't have one yet — see
/// `EvacuationCentersRepositoryImpl.refreshCenterPhotoIfMissing`'s doc
/// comment for why this gap exists (the plain centers list never
/// returns `photo_url`) and why it's safe to always attempt this: it's
/// a cheap no-op whenever a photo is already cached or the fetch/write
/// fails for any reason. Returns whether a refresh of
/// [allEvacuationCentersProvider] is worthwhile — watched by a small,
/// invisible trigger widget on the details page (see
/// `evacuation_center_details_page.dart`) rather than by
/// [CenterPhotoCard] itself, so that widget's existing behavior stays
/// completely unchanged.
@riverpod
Future<void> centerPhotoRefresh(Ref ref, int centerId) async {
  final repository = ref.watch(evacuationCentersRepositoryProvider);
  final refreshed = await repository.refreshCenterPhotoIfMissing(centerId);
  if (refreshed) {
    ref.invalidate(allEvacuationCentersProvider);
  }
}
