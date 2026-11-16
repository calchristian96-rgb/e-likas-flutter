import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/database/staff_database.dart';
import 'package:elikas_mobile/features/outbox/data/outbox_repository.dart';
import 'package:elikas_mobile/features/outbox/domain/pending_action.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';

/// A Laravel refusal body: `{success, message, errors}`.
Map<String, dynamic> refusal(String message, [String? key]) => {
  'success': false,
  'message': message,
  'errors': key == null
      ? null
      : {
          key: [message],
        },
};

/// For each kind: its path, the backend's own "already happened" answer
/// (from BoxReliefService, EvacueeController, GisSituationController,
/// BarangayCountSubmissionController), and a different refusal of the
/// same request that must NOT count as done.
final cases = <(PendingActionKind, String, (int, Object?), (int, Object?))>[
  (
    PendingActionKind.boxHandout,
    '/box-relief/rounds/3/handouts',
    (422, refusal('This family already got its box for Round 1.', 'family_id')),
    (422, refusal('Nothing received yet for Round 1.', 'family_id')),
  ),
  (
    PendingActionKind.boxHandoutVoid,
    '/box-relief/handouts/9/void',
    (422, refusal('This record was already voided.', 'reason')),
    (422, refusal('The reason must be at least 3 characters.', 'reason')),
  ),
  (
    PendingActionKind.dispatchConfirm,
    '/box-relief/dispatches/2/confirm',
    (
      422,
      refusal('This delivery was already confirmed.', 'confirmed_quantity'),
    ),
    (
      422,
      refusal(
        'The confirmed quantity may not be greater than 3.',
        'confirmed_quantity',
      ),
    ),
  ),
  (
    PendingActionKind.barangayStatus,
    '/gis/barangay-status',
    (
      422,
      refusal(
        'Binatagan is already marked "Watch". Add a note to record an update.',
        'status',
      ),
    ),
    (
      422,
      refusal(
        '"Typhoon X" is closed. The situation can only be marked during an open event.',
        'evacuation_event_id',
      ),
    ),
  ),
  (
    PendingActionKind.countSubmission,
    '/count-submissions',
    (
      422,
      refusal(
        'This count is already waiting for CSWD, and nothing has changed since it was submitted.',
      ),
    ),
    (422, refusal('The event is not active.', 'evacuation_event_id')),
  ),
  (
    PendingActionKind.checkOut,
    '/evacuees/1804/check-out',
    (
      404,
      refusal('This evacuee has no active evacuation record to close out.'),
    ),
    (422, refusal('The selected status is invalid.', 'status')),
  ),
];

void main() {
  late StaffDatabase db;
  late FakeStaffApi api;
  late OutboxRepository repo;

  setUp(() {
    db = StaffDatabase.forExecutor(NativeDatabase.memory());
    api = FakeStaffApi();
    repo = OutboxRepository(
      db,
      api,
      ConnectivityService.forTesting(
        hasInterface: () async => true,
        probe: () async => true,
        resultCacheTtl: Duration.zero,
      ),
      4,
    );
  });
  tearDown(() => db.close());

  /// Queue the action, lose the first answer (the request may have got
  /// through), then Try again and get [second].
  Future<PendingAction?> retryAfterLostAnswer(
    PendingActionKind kind,
    String path,
    (int, Object?) second,
  ) async {
    final a = await repo.enqueue(
      kind: kind,
      method: 'POST',
      path: path,
      body: const {'x': 1},
      summary: kind.name,
    );
    api.answer('POST $path', DioExceptionType.receiveTimeout);
    api.answer('POST $path', second);
    await repo.run();
    await repo.retry(a.localId);
    await repo.run();
    final left = await repo.getAll();
    return left.isEmpty ? null : left.single;
  }

  for (final (kind, path, already, other) in cases) {
    test(
      '${kind.name}: the "already happened" answer on a retry is done',
      () async {
        expect(await retryAfterLostAnswer(kind, path, already), isNull);
      },
    );

    test(
      '${kind.name}: any other refusal on a retry needs a look, with its message',
      () async {
        final row = await retryAfterLostAnswer(kind, path, other);
        expect(row, isNotNull);
        expect(row!.needsAttention, isTrue);
        final body = other.$2 as Map<String, dynamic>;
        expect(row.lastErrorMessage, contains(body['message'] as String));
      },
    );
  }

  test(
    'the "already happened" answer on a first attempt still needs a look',
    () async {
      await repo.enqueue(
        kind: PendingActionKind.boxHandout,
        method: 'POST',
        path: '/box-relief/rounds/3/handouts',
        body: const {'family_id': 548},
        summary: 'Box for Fe Flor',
      );
      api.answer('POST /box-relief/rounds/3/handouts', cases.first.$3);
      await repo.run();
      expect((await repo.getAll()).single.needsAttention, isTrue);
    },
  );

  test(
    'kinds with no "already happened" refusal never count a 422 as done',
    () async {
      for (final kind in [
        PendingActionKind.shortfallRequest,
        PendingActionKind.centerLocation,
        PendingActionKind.facilityRequest,
      ]) {
        expect(kind.alreadyHappened, isNull);
      }
      final row = await retryAfterLostAnswer(
        PendingActionKind.shortfallRequest,
        '/box-relief/rounds/3/shortfall-requests',
        (
          422,
          refusal('You can request at most 0 boxes for Round 1.', 'quantity'),
        ),
      );
      expect(row!.needsAttention, isTrue);
    },
  );

  test('the phrase must be under the right error key and status', () {
    final rule = PendingActionKind.boxHandout.alreadyHappened!;
    expect(
      rule.matches(
        422,
        refusal('This family already got its box for Round 2.', 'family_id'),
      ),
      isTrue,
    );
    // Same words under another key, or another status: not a match.
    expect(
      rule.matches(
        422,
        refusal('This family already got its box.', 'quantity'),
      ),
      isFalse,
    );
    expect(
      rule.matches(
        409,
        refusal('This family already got its box.', 'family_id'),
      ),
      isFalse,
    );
  });
}
