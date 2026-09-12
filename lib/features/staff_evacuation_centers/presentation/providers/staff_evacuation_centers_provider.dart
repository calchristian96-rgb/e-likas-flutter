import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/database/resident_database.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/staff_api_client.dart';
import '../../../evacuation_centers/data/datasources/evacuation_centers_local_datasource.dart';
import '../../../evacuation_centers/domain/entities/evacuation_center.dart';
import '../../data/datasources/staff_evacuation_centers_remote_datasource.dart';
import '../../data/repositories/staff_evacuation_centers_repository_impl.dart';
import '../../domain/entities/evacuation_center_draft.dart';
import '../../domain/repositories/staff_evacuation_centers_repository.dart';

part 'staff_evacuation_centers_provider.g.dart';

@riverpod
StaffEvacuationCentersRepository staffEvacuationCentersRepository(Ref ref) {
  return StaffEvacuationCentersRepositoryImpl(
    remote: StaffEvacuationCentersRemoteDataSource(
      ref.watch(staffApiClientProvider),
    ),
    connectivity: ref.watch(connectivityServiceProvider),
    // The same public/resident Drift cache `allEvacuationCentersProvider`
    // reads from (`core/database/resident_database.dart`) — not the
    // encrypted staff one. A successful create/update/detail fetch
    // here writes its richer result straight into it, authoritative
    // for `photoUrl`, so Center Details never has to wait for (or risk
    // losing the photo to) a separate public refetch. See
    // `StaffEvacuationCentersRepositoryImpl`'s doc comment.
    residentCache: EvacuationCentersLocalDatasource(
      ref.watch(residentDatabaseProvider),
    ),
  );
}

/// The full authenticated detail for one center — drives the Staff
/// Center Detail page (Edit visibility, prefill). `autoDispose` +
/// `keepAlive` deliberately not used: a fresh fetch every time this
/// page opens is correct here (online-only feature, no reason to show
/// stale ownership/occupancy data).
@riverpod
Future<EvacuationCenter> staffCenterDetail(Ref ref, int id) async {
  final result = await ref
      .watch(staffEvacuationCentersRepositoryProvider)
      .getCenterDetail(id);
  return switch (result) {
    Success(:final value) => value,
    Failed(:final failure) => throw failure,
  };
}

/// A callable rather than a plain method so the form page can await a
/// [Result] directly without reaching through the repository provider
/// itself — mirrors `staffSyncNowProvider`'s shape in the family-
/// registration feature.
@riverpod
Future<Result<EvacuationCenter>> Function({
  required EvacuationCenterDraft draft,
  File? photo,
})
createEvacuationCenter(Ref ref) {
  final repository = ref.watch(staffEvacuationCentersRepositoryProvider);
  return ({required EvacuationCenterDraft draft, File? photo}) {
    return repository.createCenter(draft, photo: photo);
  };
}

@riverpod
Future<Result<EvacuationCenter>> Function({
  required int id,
  required EvacuationCenterDraft draft,
  File? photo,
  bool locationWasCleared,
})
updateEvacuationCenter(Ref ref) {
  final repository = ref.watch(staffEvacuationCentersRepositoryProvider);
  return ({
    required int id,
    required EvacuationCenterDraft draft,
    File? photo,
    bool locationWasCleared = false,
  }) {
    return repository.updateCenter(
      id,
      draft,
      photo: photo,
      locationWasCleared: locationWasCleared,
    );
  };
}
