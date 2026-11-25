import 'dart:io';

import 'package:drift/native.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/database/staff_database.dart';
import 'package:elikas_mobile/features/ec_board/data/datasources/ec_board_local_datasource.dart';
import 'package:elikas_mobile/features/family_registration/data/datasources/lookup_local_datasource.dart';
import 'package:elikas_mobile/features/family_registration/data/datasources/pending_queue_local_datasource.dart';
import 'package:elikas_mobile/features/family_registration/data/repositories/pending_queue_repository_impl.dart';
import 'package:elikas_mobile/features/family_registration/domain/repositories/lookup_repository.dart';
import 'package:elikas_mobile/features/outbox/data/outbox_repository.dart';
import 'package:elikas_mobile/features/outbox/data/sent_history_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';

/// `test/fixtures/staff_db_0_4_0.sqlite` was written by the 0.4.0+9 code
/// itself (schema 11, main 14da9d0) with unsent records left in it: a
/// family registration, an EC Board person, a waiting check-out and a
/// box handout that needs attention (for account 4). A phone updating
/// to 0.5.0 opens that file with the schema 12 code.
void main() {
  late StaffDatabase db;

  setUp(() async {
    // The upgrade writes to the file: work on a copy.
    final dir = await Directory.systemTemp.createTemp('elikas_upgrade');
    final copy = await File(
      'test/fixtures/staff_db_0_4_0.sqlite',
    ).copy('${dir.path}/elikas_staff.sqlite');
    db = StaffDatabase.forExecutor(NativeDatabase(copy));
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });
  });

  test('the migration runs: schema 12, the new table and columns', () async {
    final centers = await LookupLocalDataSource(
      db,
    ).getCachedEvacuationCenters();
    expect(centers.single.name, 'LWCES (B)');
    expect(centers.single.currentOccupancy, isNull);
    expect(centers.single.figuresEventId, isNull);
    expect(await db.select(db.sentRecords).get(), isEmpty);
    final version = await db
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((r) => r.data['user_version']);
    expect(version, 12);
  });

  test('unsent family registrations and EC Board people survive', () async {
    final queue = PendingQueueRepositoryImpl(
      PendingQueueLocalDataSource(db),
      _NoLookups(),
      ownerStaffId: 4,
    );
    final waiting = await queue.getAll();
    expect(waiting.single.localId, 'reg-1');
    expect(waiting.single.headOfFamilyName, 'Reyes, Juan');
    final detail = (await queue.getPendingQueueInOrder()).single;
    expect(detail.draft.evacuationEventId, 49);
    expect(detail.draft.evacuationCenterId, 7);

    final entry = await EcBoardLocalDataSource(db).getByLocalId('ec-1');
    expect(entry, isNotNull);
    expect(entry!.householdLabel, 'Santos family');
  });

  test('waiting actions survive, are sent, and appear in Sent', () async {
    final api = FakeStaffApi();
    final outbox = OutboxRepository(
      db,
      api,
      ConnectivityService.forTesting(
        hasInterface: () async => true,
        probe: () async => true,
        resultCacheTtl: Duration.zero,
      ),
      4,
      sentHistory: SentHistoryRepository(db, 4),
    );
    final before = await outbox.getAll();
    expect(before.map((a) => a.localId), ['act-1', 'act-2']);
    expect(before.last.needsAttention, isTrue);
    expect(before.first.eventId, isNull);

    final result = await outbox.run();
    expect(result.sent, 1);
    expect(api.calls, ['POST /evacuees/31/check-out']);
    // The one that needs a look stays for the user.
    expect((await outbox.getAll()).single.localId, 'act-2');
    final sent = await SentHistoryRepository(db, 4).list();
    expect(sent.single.summary, 'Check-out of Ana Reyes');
  });
}

class _NoLookups implements LookupRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
