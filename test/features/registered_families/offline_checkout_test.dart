import 'package:drift/native.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/database/staff_database.dart';
import 'package:elikas_mobile/core/error/failure.dart';
import 'package:elikas_mobile/core/error/result.dart';
import 'package:elikas_mobile/features/outbox/data/outbox_repository.dart';
import 'package:elikas_mobile/features/outbox/domain/pending_action.dart';
import 'package:elikas_mobile/features/outbox/presentation/outbox_providers.dart';
import 'package:elikas_mobile/features/registered_families/domain/entities/family_record.dart';
import 'package:elikas_mobile/features/registered_families/domain/entities/registered_families_snapshot.dart';
import 'package:elikas_mobile/features/registered_families/domain/entities/registered_family.dart';
import 'package:elikas_mobile/features/registered_families/domain/repositories/registered_families_repository.dart';
import 'package:elikas_mobile/features/registered_families/presentation/providers/registered_families_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';

class _OfflineFamilies implements RegisteredFamiliesRepository {
  @override
  Future<Result<void>> checkOut(int evacueeId, CheckOutReason reason) async =>
      const Failed(NetworkFailure('No connection.'));

  @override
  Future<Result<RegisteredFamiliesSnapshot>> getAll() =>
      throw UnimplementedError();

  @override
  Future<List<RegisteredFamily>> getCachedOnly() => throw UnimplementedError();

  @override
  Future<Result<FamilyRecord>> getRecord(int familyId) =>
      throw UnimplementedError();
}

void main() {
  test('a check-out with no connection is queued, not lost', () async {
    final db = StaffDatabase.forExecutor(NativeDatabase.memory());
    addTearDown(db.close);
    final outbox = OutboxRepository(
      db,
      FakeStaffApi(),
      ConnectivityService.forTesting(
        hasInterface: () async => false,
        probe: () async => false,
        resultCacheTtl: Duration.zero,
      ),
      4,
    );
    final container = ProviderContainer(
      overrides: [
        registeredFamiliesRepositoryProvider.overrideWithValue(
          _OfflineFamilies(),
        ),
        outboxRepositoryProvider.overrideWithValue(outbox),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(checkOutEvacueeProvider)(
      1804,
      CheckOutReason.returnedHome,
    );
    expect(result, isA<Success<void>>());
    final queued = (await outbox.getAll()).single;
    expect(queued.kind, PendingActionKind.checkOut);
    expect(queued.path, '/evacuees/1804/check-out');
    expect(queued.body, {'status': 'returned_home'});
  });
}
