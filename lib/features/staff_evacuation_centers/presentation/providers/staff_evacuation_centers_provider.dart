import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/database/resident_database.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/staff_api_client.dart';
import '../../../evacuation_centers/data/datasources/evacuation_centers_local_datasource.dart';
import '../../../evacuation_centers/domain/entities/evacuation_center.dart';
import '../../data/datasources/staff_evacuation_centers_remote_datasource.dart';
import '../../data/repositories/staff_evacuation_centers_repository_impl.dart';
import '../../domain/repositories/staff_evacuation_centers_repository.dart';
import '../../../staff_shell/current_event.dart';

part 'staff_evacuation_centers_provider.g.dart';

@riverpod
StaffEvacuationCentersRepository staffEvacuationCentersRepository(Ref ref) {
  return StaffEvacuationCentersRepositoryImpl(
    StaffEvacuationCentersRemoteDataSource(ref.watch(staffApiClientProvider)),
    ref.watch(connectivityServiceProvider),
    EvacuationCentersLocalDatasource(ref.watch(residentDatabaseProvider)),
  );
}

/// The full authenticated detail for one center, fresh every time the
/// page opens (online only).
@riverpod
Future<EvacuationCenter> staffCenterDetail(Ref ref, int id) async {
  int? eventId;
  try {
    eventId = (await ref.watch(currentStaffEventProvider.future))?.id;
  } catch (_) {
    // No event known yet: the server uses the user's selected event.
  }
  final result = await ref
      .watch(staffEvacuationCentersRepositoryProvider)
      .getCenterDetail(id, eventId: eventId);
  return switch (result) {
    Success(:final value) => value,
    Failed(:final failure) => throw failure,
  };
}
