import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/staff_api_client.dart';
import '../../data/datasources/family_registration_remote_datasource.dart';
import '../../data/repositories/family_registration_repository_impl.dart';
import '../../domain/repositories/family_registration_repository.dart';

part 'registration_submit_provider.g.dart';

/// The single online-submit path (`POST /families/register`), shared
/// by the registration form's "try online first" branch and
/// `StaffSyncService` — one wiring for
/// [FamilyRegistrationRepository], not two.
@riverpod
FamilyRegistrationRepository registrationSubmit(Ref ref) {
  return FamilyRegistrationRepositoryImpl(
    FamilyRegistrationRemoteDataSource(ref.watch(staffApiClientProvider)),
  );
}
