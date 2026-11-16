import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/database/staff_database.dart';
import 'package:elikas_mobile/features/outbox/data/outbox_repository.dart';
import 'package:elikas_mobile/features/outbox/domain/pending_action.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';

void main() {
  late StaffDatabase db;
  late FakeStaffApi api;
  late bool online;

  OutboxRepository repo({int? owner = 4}) => OutboxRepository(
    db,
    api,
    ConnectivityService.forTesting(
      hasInterface: () async => online,
      probe: () async => online,
      resultCacheTtl: Duration.zero,
    ),
    owner,
  );

  Future<PendingAction> handout(OutboxRepository r, {int family = 548}) =>
      r.enqueue(
        kind: PendingActionKind.boxHandout,
        method: 'POST',
        path: '/box-relief/rounds/3/handouts',
        body: {'family_id': family},
        summary: 'Box for family $family',
      );

  setUp(() {
    db = StaffDatabase.forExecutor(NativeDatabase.memory());
    api = FakeStaffApi();
    online = true;
  });
  tearDown(() => db.close());

  test(
    'an accepted action leaves the queue; the request is sent as queued',
    () async {
      final r = repo();
      await handout(r);
      final result = await r.run();
      expect(result.sent, 1);
      expect(await r.getAll(), isEmpty);
      expect(api.calls, ['POST /box-relief/rounds/3/handouts']);
      expect(api.bodies.single, {'family_id': 548});
    },
  );

  test('offline: nothing is attempted and the action waits', () async {
    online = false;
    final r = repo();
    await handout(r);
    final result = await r.run();
    expect(result.wasOffline, isTrue);
    expect(api.calls, isEmpty);
    expect((await r.getAll()).single.needsAttention, isFalse);
  });

  test('a refusal needs a look and is not retried on its own', () async {
    final r = repo();
    await r.enqueue(
      kind: PendingActionKind.shortfallRequest,
      method: 'POST',
      path: '/box-relief/rounds/3/shortfall-requests',
      body: const {},
      summary: 'Shortfall request',
    );
    api.answer('POST /box-relief/rounds/3/shortfall-requests', 422);
    expect((await r.run()).needAttention, 1);
    final row = (await r.getAll()).single;
    expect(row.needsAttention, isTrue);
    expect(row.lastErrorMessage, contains('Refused for this test.'));
    await r.run();
    expect(api.calls, hasLength(1));
  });

  test(
    'a lost answer, then a repeat refusal of a handout: it was already done',
    () async {
      final r = repo();
      final a = await handout(r);
      api.answer(
        'POST /box-relief/rounds/3/handouts',
        DioExceptionType.receiveTimeout,
      );
      api.answer('POST /box-relief/rounds/3/handouts', (
        422,
        {
          'success': false,
          'message': 'This family already got its box for Round 1.',
          'errors': {
            'family_id': ['This family already got its box for Round 1.'],
          },
        },
      ));
      await r.run();
      expect((await r.getAll()).single.needsAttention, isTrue);
      await r.retry(a.localId);
      final result = await r.run();
      expect(result.sent, 1);
      expect(await r.getAll(), isEmpty);
    },
  );

  test('a connection drop keeps the action for the next run', () async {
    final r = repo();
    await handout(r);
    api.answer(
      'POST /box-relief/rounds/3/handouts',
      DioExceptionType.connectionError,
    );
    await r.run();
    final row = (await r.getAll()).single;
    expect(row.needsAttention, isFalse);
    expect(row.attemptCount, 1);
  });

  test('401 stops the run and leaves everything queued', () async {
    final r = repo();
    await handout(r, family: 1);
    await handout(r, family: 2);
    api.answer('POST /box-relief/rounds/3/handouts', 401);
    final result = await r.run();
    expect(result.stoppedForAuth, isTrue);
    expect(await r.getAll(), hasLength(2));
    expect(api.calls, hasLength(1));
  });

  test('each account sees only its own queue', () async {
    await handout(repo(owner: 4));
    expect(await repo(owner: 9).getAll(), isEmpty);
    expect(await repo(owner: 4).getAll(), hasLength(1));
  });
}
