import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/database/staff_database.dart';
import 'package:elikas_mobile/core/error/failure.dart';
import 'package:elikas_mobile/core/error/result.dart';
import 'package:elikas_mobile/features/family_registration/data/services/staff_sync_service.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/family_registration_draft.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/pending_registration.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/pending_registration_status.dart';
import 'package:elikas_mobile/features/family_registration/domain/repositories/family_registration_repository.dart';
import 'package:elikas_mobile/features/family_registration/domain/repositories/pending_queue_repository.dart';
import 'package:elikas_mobile/features/outbox/data/outbox_repository.dart';
import 'package:elikas_mobile/features/outbox/data/sent_family_api.dart';
import 'package:elikas_mobile/features/outbox/data/sent_history_repository.dart';
import 'package:elikas_mobile/features/outbox/domain/pending_action.dart';
import 'package:elikas_mobile/features/outbox/domain/sent_record.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';

ConnectivityService _connectivity(bool Function() online) =>
    ConnectivityService.forTesting(
      hasInterface: () async => online(),
      probe: () async => online(),
      resultCacheTtl: Duration.zero,
    );

void main() {
  late StaffDatabase db;
  late FakeStaffApi api;
  late bool online;
  late DateTime now;

  SentHistoryRepository history({int? owner = 4}) =>
      SentHistoryRepository(db, owner, now: () => now);

  setUp(() async {
    db = StaffDatabase.forExecutor(NativeDatabase.memory());
    api = FakeStaffApi();
    online = true;
    now = DateTime(2026, 11, 25, 9);
    await db
        .into(db.lookupEvacuationCenters)
        .insert(
          LookupEvacuationCentersCompanion.insert(
            id: const Value(7),
            name: 'LWCES (B)',
            barangayId: 13,
            status: 'active',
          ),
        );
  });
  tearDown(() => db.close());

  group('queued actions', () {
    OutboxRepository outbox() => OutboxRepository(
      db,
      api,
      _connectivity(() => online),
      4,
      sentHistory: history(),
    );

    test('an accepted action leaves the queue but stays in Sent, with the '
        "server's id, its event and its place", () async {
      final r = outbox();
      await r.enqueue(
        kind: PendingActionKind.facilityRequest,
        method: 'POST',
        path: '/evacuation-centers/7/facility-requests',
        body: const {'item': 'Water'},
        summary: 'Water for LWCES',
        eventId: 49,
      );
      api.answer('POST /evacuation-centers/7/facility-requests', (
        201,
        {
          'success': true,
          'data': {'id': 912},
        },
      ));
      expect((await r.run()).sent, 1);
      expect(await r.getAll(), isEmpty);

      final sent = (await history().list(eventId: 49)).single;
      expect(sent.kind, SentRecordKind.action);
      expect(sent.actionKind, PendingActionKind.facilityRequest);
      expect(sent.summary, 'Water for LWCES');
      expect(sent.place, 'LWCES (B)');
      expect(sent.serverId, 912);
      expect(sent.eventId, 49);
      // Actions have no server edit: read-only.
      expect(sent.canEdit, isFalse);
    });

    test('a refused action is not in Sent', () async {
      final r = outbox();
      await r.enqueue(
        kind: PendingActionKind.shortfallRequest,
        method: 'POST',
        path: '/box-relief/rounds/3/shortfall-requests',
        body: const {},
        summary: 'Shortfall',
      );
      api.answer('POST /box-relief/rounds/3/shortfall-requests', 422);
      await r.run();
      expect(await history().list(), isEmpty);
    });

    test(
      "the body's own evacuation_event_id wins over the selected one",
      () async {
        final r = outbox();
        final a = await r.enqueue(
          kind: PendingActionKind.countSubmission,
          method: 'POST',
          path: '/count-submissions',
          body: const {'evacuation_event_id': 48},
          summary: 'Final count',
          eventId: 49,
        );
        expect(a.eventId, 48);
        expect((await r.getAll()).single.eventId, 48);
      },
    );
  });

  group('the Sent list', () {
    Future<void> sentAt(DateTime at, String id, {int? event = 49}) async {
      now = at;
      await history().recordAction(
        PendingAction(
          localId: id,
          kind: PendingActionKind.checkOut,
          method: 'POST',
          path: '/evacuees/1/check-out',
          body: const {},
          summary: 'Check-out $id',
          status: PendingActionStatus.pending,
          createdAt: at,
          eventId: event,
        ),
      );
    }

    test(
      'newest first, the selected event and rows of no event only',
      () async {
        await sentAt(DateTime(2026, 11, 25, 8), 'a');
        await sentAt(DateTime(2026, 11, 25, 9), 'b', event: 48);
        await sentAt(DateTime(2026, 11, 25, 10), 'c', event: null);
        await sentAt(DateTime(2026, 11, 25, 11), 'd');
        final rows = await history().list(eventId: 49);
        expect(rows.map((r) => r.localId), ['d', 'c', 'a']);
        // Another account sees none of them.
        expect(await history(owner: 5).list(eventId: 49), isEmpty);
      },
    );

    test('kept 14 days, at most 200 rows', () async {
      await sentAt(DateTime(2026, 11, 1), 'old');
      final start = DateTime(2026, 11, 20);
      for (var i = 0; i < 205; i++) {
        await sentAt(start.add(Duration(minutes: i)), 'n$i');
      }
      final all = await db.select(db.sentRecords).get();
      expect(all, hasLength(SentHistoryRepository.maxRows));
      expect(all.any((r) => r.localId == 'old'), isFalse);
      expect(all.any((r) => r.localId == 'n0'), isFalse);
      expect(all.any((r) => r.localId == 'n204'), isTrue);
    });
  });

  test(
    'a synced registration is kept in Sent with its family id, editable',
    () async {
      final queue = _Queue();
      final service = StaffSyncService(
        pendingQueueRepository: queue,
        registrationRepository: _Registrations(),
        connectivity: _connectivity(() => true),
        sentHistory: history(),
      );
      final result = await service.run();
      expect(result.processed, 1);
      expect(queue.synced, ['reg-1']);
      final sent = (await history().list(eventId: 49)).single;
      expect(sent.kind, SentRecordKind.registration);
      expect(sent.summary, 'Reyes, Juan');
      expect(sent.memberCount, 4);
      expect(sent.place, 'LWCES (B)');
      expect(sent.serverFamilyId, 548);
      expect(sent.canEdit, isTrue);
    },
  );

  group('editing a sent family on the server', () {
    SentFamilyApi editApi() => SentFamilyApi(api, _connectivity(() => online));

    test(
      'offline: nothing is sent, an internet connection is needed',
      () async {
        online = false;
        final result = await editApi().updateMember(31, {'first_name': 'Ana'});
        expect((result as Failed).failure, isA<NeedsConnectionFailure>());
        expect(api.calls, isEmpty);
      },
    );

    test('PATCH /evacuees/{id} and /families/{id}/household', () async {
      api.answer('PATCH /evacuees/31', (
        200,
        {
          'success': true,
          'data': {
            'id': 31,
            'full_name': 'Ana Reyes',
            'first_name': 'Ana',
            'sex': 'female',
            'sectoral': {'is_pwd': true, 'pwd_type': 'Visual'},
          },
        },
      ));
      final member = await editApi().updateMember(31, {'first_name': 'Ana'});
      final value = (member as Success).value;
      expect(value.firstName, 'Ana');
      expect(value.isPwd, isTrue);
      expect(value.pwdType, 'Visual');
      await editApi().updateHousehold(548, {
        'head_of_family_evacuee_id': 31,
        'is_single_headed': true,
      });
      expect(api.calls, [
        'PATCH /evacuees/31',
        'PATCH /families/548/household',
      ]);
      expect(api.bodies.last, {
        'head_of_family_evacuee_id': 31,
        'is_single_headed': true,
      });
    });

    test("a 422 comes back with the server's field messages", () async {
      api.answer('PATCH /evacuees/31', (
        422,
        {
          'success': false,
          'message': 'The first name field must be a string.',
          'errors': {
            'first_name': ['The first name field must be a string.'],
          },
        },
      ));
      final result = await editApi().updateMember(31, {'first_name': null});
      final failure = (result as Failed).failure;
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).fieldErrors['first_name'], [
        'The first name field must be a string.',
      ]);
    });
  });

  test('upgrading schema 11 keeps queued actions and saved centers, adds '
      'the center figures, the event of an action and the Sent list', () async {
    final old = StaffDatabase.forExecutor(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE lookup_evacuation_centers (
              id INTEGER NOT NULL PRIMARY KEY, name TEXT NOT NULL,
              barangay_id INTEGER NOT NULL, status TEXT NOT NULL,
              approval_status TEXT NOT NULL DEFAULT 'approved',
              has_pending_change INTEGER NOT NULL DEFAULT 0,
              rejection_reason TEXT NULL)
          ''');
          raw.execute('''
            CREATE TABLE pending_actions (
              local_id TEXT NOT NULL PRIMARY KEY, kind TEXT NOT NULL,
              method TEXT NOT NULL, path TEXT NOT NULL,
              body_json TEXT NOT NULL, summary TEXT NOT NULL,
              subject_key TEXT NULL, status TEXT NOT NULL,
              attempt_count INTEGER NOT NULL DEFAULT 0,
              last_error_message TEXT NULL,
              created_at_epoch_ms INTEGER NOT NULL,
              owner_staff_id INTEGER NOT NULL)
          ''');
          raw.execute('''
            INSERT INTO lookup_evacuation_centers (id, name, barangay_id, status)
            VALUES (7, 'LWCES (B)', 13, 'active')
          ''');
          raw.execute('''
            INSERT INTO pending_actions (local_id, kind, method, path,
              body_json, summary, status, created_at_epoch_ms, owner_staff_id)
            VALUES ('a1', 'checkOut', 'POST', '/evacuees/1/check-out', '{}',
              'Check-out', 'pending', 1, 4)
          ''');
          raw.execute('PRAGMA user_version = 11');
        },
      ),
    );
    addTearDown(old.close);
    final center = await old.select(old.lookupEvacuationCenters).getSingle();
    expect(center.name, 'LWCES (B)');
    expect(center.currentOccupancy, isNull);
    expect(center.figuresEventId, isNull);
    final action = await old.select(old.pendingActions).getSingle();
    expect(action.localId, 'a1');
    expect(action.eventId, isNull);
    expect(await old.select(old.sentRecords).get(), isEmpty);
    expect(old.schemaVersion, 12);
  });
}

class _Queue implements PendingQueueRepository {
  final synced = <String>[];

  @override
  Future<List<PendingRegistrationDetail>> getPendingQueueInOrder() async => [
    PendingRegistrationDetail(
      summary: PendingRegistrationSummary(
        localId: 'reg-1',
        status: PendingRegistrationStatus.pending,
        headOfFamilyName: 'Reyes, Juan',
        memberCount: 4,
        barangayName: 'Binatagan',
        createdAt: DateTime(2026, 11, 25),
        updatedAt: DateTime(2026, 11, 25),
      ),
      draft: const FamilyRegistrationDraft(
        evacuationEventId: 49,
        barangayId: 13,
        displacementType: 'inside_center',
        evacuationCenterId: 7,
      ),
    ),
  ];

  @override
  Future<void> markSyncing(String localId) async {}

  @override
  Future<void> markSynced(String localId) async => synced.add(localId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Registrations implements FamilyRegistrationRepository {
  @override
  Future<Result<int>> submit(
    FamilyRegistrationDraft draft, {
    String? clientRef,
  }) async => const Success(548);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
