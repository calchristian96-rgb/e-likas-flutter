import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/debug/center_photo_debug_log.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/staff_api_error_mapper.dart';
import '../../../evacuation_centers/data/datasources/evacuation_centers_local_datasource.dart';
import '../../../evacuation_centers/data/models/evacuation_center_model.dart';
import '../../../evacuation_centers/domain/entities/evacuation_center.dart';
import '../../domain/entities/evacuation_center_draft.dart';
import '../../domain/repositories/staff_evacuation_centers_repository.dart';
import '../datasources/staff_evacuation_centers_remote_datasource.dart';

/// Deliberately online-only: every method checks connectivity first
/// and fails fast with [NetworkFailure] rather than queuing anything
/// (see this feature's top-level doc comment — Add/Edit Center is not
/// offline-capable, unlike Family Registration, and must never become
/// so by accident).
///
/// Also the fix for a real device bug: the authenticated staff
/// resource is the *richest* response this app ever receives for a
/// center (the only one with a guaranteed-fresh `photo_url` right
/// after an upload) — but until this fix, that response was thrown
/// away the moment `toEntity()` ran, and the resident Center Details
/// screen only ever read from the separate public-list-backed cache
/// (`EvacuationCentersLocalDatasource`, Drift-backed), which the next
/// `allEvacuationCentersProvider` refresh would repopulate from
/// `/public/evacuation-centers` — an endpoint that never returns
/// `photo_url` at all. [_residentCache] is the same cache that
/// datasource writes to; caching the staff response into it here,
/// authoritative for `photoUrl` (`photoUrlIsAuthoritative: true`,
/// same as the GIS write path), means Center Details can see the new
/// photo immediately, and `mergeOverExisting`'s merge (see that
/// method's doc comment) stops a subsequent public refresh from
/// nulling it back out.
class StaffEvacuationCentersRepositoryImpl
    implements StaffEvacuationCentersRepository {
  StaffEvacuationCentersRepositoryImpl({
    required StaffEvacuationCentersRemoteDataSource remote,
    required ConnectivityService connectivity,
    required EvacuationCentersLocalDatasource residentCache,
  }) : _remote = remote,
       _connectivity = connectivity,
       _residentCache = residentCache;

  final StaffEvacuationCentersRemoteDataSource _remote;
  final ConnectivityService _connectivity;
  final EvacuationCentersLocalDatasource _residentCache;

  /// Persists [model] into the same Isar collection the resident
  /// Center Details/GIS Map read from, trusting its `photoUrl` outright
  /// (the staff resource always includes the real key, same as GIS —
  /// see `EvacuationCenterModel.mergeOverExisting`'s doc comment).
  /// Best-effort: a cache-write failure shouldn't turn a successful
  /// server save into a reported error, so this deliberately never
  /// throws into the caller's `Result`.
  Future<void> _cacheAuthoritative(EvacuationCenterModel model) async {
    try {
      await _residentCache.cacheCenters([model], photoUrlIsAuthoritative: true);
      if (kDebugMode) {
        final cached = await _residentCache.getCachedCenters();
        String? cachedPhotoUrl;
        for (final c in cached) {
          if (c.id == model.id) {
            cachedPhotoUrl = c.photoUrl;
            break;
          }
        }
        centerPhotoDebugLog('cached photoUrl after write=$cachedPhotoUrl');
      }
    } catch (_) {
      // Best-effort — see doc comment above.
    }
  }

  /// TEMPORARY debugging only (Step 5 of the photo-bug trace): a
  /// second, independent `GET /evacuation-centers/{id}` right after a
  /// successful create/update, purely to log what the server itself
  /// now has stored for this center — separates "upload failed
  /// server-side" from "upload succeeded but Flutter lost the value
  /// somewhere after receiving the create/update response." Never
  /// affects the real result: any failure here is swallowed, and this
  /// entire call is skipped outside `kDebugMode` so it never costs a
  /// release build an extra request.
  Future<void> _debugReverifyPersisted(int id) async {
    if (!kDebugMode) return;
    try {
      await _remote.getCenter(id);
    } catch (_) {
      // Diagnostic only — see doc comment above.
    }
  }

  static const _offlineMessage =
      'Internet connection is required to add or edit evacuation centers.';

  Future<Result<T>> _guardOnline<T>(Future<Result<T>> Function() action) async {
    if (!await _connectivity.hasConnection) {
      return const Failed(NetworkFailure(_offlineMessage));
    }
    return action();
  }

  @override
  Future<Result<EvacuationCenter>> getCenterDetail(int id) {
    return _guardOnline(() async {
      try {
        final model = await _remote.getCenter(id);
        // Bonus consistency, not just the photo fix: viewing any
        // center's staff detail also refreshes the resident cache for
        // it, so a different staff member (or the same one, later)
        // opening Center Details never sees data staler than the last
        // time anyone looked at this center's staff detail.
        await _cacheAuthoritative(model);
        return Success(model.toEntity());
      } on DioException catch (e) {
        return Failed(mapStaffDioError(e));
      }
    });
  }

  @override
  Future<Result<EvacuationCenter>> createCenter(
    EvacuationCenterDraft draft, {
    File? photo,
  }) {
    return _guardOnline(() async {
      try {
        final model = await _remote.createCenter(draft, photo: photo);
        await _cacheAuthoritative(model);
        await _debugReverifyPersisted(model.id);
        return Success(model.toEntity());
      } on DioException catch (e) {
        return Failed(mapStaffDioError(e));
      }
    });
  }

  @override
  Future<Result<EvacuationCenter>> updateCenter(
    int id,
    EvacuationCenterDraft draft, {
    File? photo,
    bool locationWasCleared = false,
  }) {
    return _guardOnline(() async {
      try {
        // The one combination a single multipart request can't express:
        // clearing a previously-set location while also replacing the
        // photo. `latitude`/`longitude` have a `sometimes` validation
        // rule (verified against `UpdateEvacuationCenterRequest`), so
        // an *omitted* multipart field means "leave the existing value
        // alone," not "clear it" — there's no way to send a literal
        // `null` through a multipart form field. A real JSON `PATCH`
        // (no file) can send an explicit `null` correctly, so that
        // request clears the location first; the follow-up multipart
        // request then omits latitude/longitude entirely, which is a
        // safe no-op against the location this first request just set.
        if (photo != null && locationWasCleared) {
          await _remote.clearLocation(id, draft);
          final model = await _remote.updateCenter(
            id,
            draft,
            photo: photo,
            includeLocation: false,
          );
          await _cacheAuthoritative(model);
          await _debugReverifyPersisted(model.id);
          return Success(model.toEntity());
        }

        final model = await _remote.updateCenter(id, draft, photo: photo);
        await _cacheAuthoritative(model);
        await _debugReverifyPersisted(model.id);
        return Success(model.toEntity());
      } on DioException catch (e) {
        return Failed(mapStaffDioError(e));
      }
    });
  }
}
