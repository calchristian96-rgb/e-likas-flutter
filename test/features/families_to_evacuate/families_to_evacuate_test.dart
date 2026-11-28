import 'package:drift/native.dart';
import 'package:elikas_mobile/core/cache/staff_read_cache.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/lookup_providers.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/database/staff_database.dart';
import 'package:elikas_mobile/features/families_to_evacuate/families_to_evacuate.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/lookup_entities.dart';
import 'package:elikas_mobile/features/outbox/data/outbox_repository.dart';
import 'package:elikas_mobile/features/outbox/domain/pending_action.dart';
import 'package:elikas_mobile/features/outbox/presentation/outbox_providers.dart';
import 'package:elikas_mobile/features/puroks/puroks.dart';
import 'package:elikas_mobile/features/staff_evacuation_centers/presentation/providers/own_centers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';
import '../../helpers/fake_staff_auth.dart';
import '../../helpers/home_fixtures.dart';

Map<String, dynamic> _family(
  int id,
  String head, {
  Map<String, dynamic>? purok,
  String status = 'expected',
  int members = 4,
}) => {
  'id': id,
  'head': head,
  'members_count': members,
  'purok': purok,
  'status': status,
  'from_past_event': id == 2,
};

const _p1 = {'id': 1, 'name': 'Purok 1', 'is_high_risk': false};
const _p3 = {'id': 3, 'name': 'Purok 3', 'is_high_risk': true, 'risk': 'flood'};

/// GET /families-to-evacuate (apps-api-2026-11-22.md section 3).
final _answer = {
  'summary': {'families': 3, 'persons': 11, 'checked_in': 1},
  'can': {'manage': true, 'check_in': true},
  'families': [
    _family(1, 'Ana Reyes', purok: _p1),
    _family(2, 'Maria Santos', purok: _p3),
    _family(3, 'Jose Cruz', purok: _p1, status: 'checked_in', members: 3),
  ],
};

class _NoSync extends StaffSyncAll {
  _NoSync(super.ref);

  @override
  Future<OutboxRunResult> call({bool automatic = true}) async =>
      const OutboxRunResult();
}

void main() {
  test(
    'per purok, high-risk puroks first; listed families are not evacuees',
    () {
      final d = FamiliesToEvacuate.fromJson(
        _answer,
        eventId: 24,
        fetchedAt: DateTime(2026),
        fromCache: false,
      );
      expect(d.byPurok.map((g) => g.$1?.name), ['Purok 3', 'Purok 1']);
      expect(d.canCheckIn, isTrue);
      expect(d.families.where((f) => f.checkedIn).single.head, 'Jose Cruz');
    },
  );

  test('the check-in body: a center, or a private house with its host', () {
    expect(checkInBody(const CheckInCenter(12, 'Hall')), {
      'evacuation_center_id': 12,
    });
    expect(
      checkInBody(
        const CheckInPrivateHouse(hostName: 'Carmen Reyes', hostPurokId: 8),
      ),
      {'host_name': 'Carmen Reyes', 'host_purok_id': 8},
    );
    expect(
      checkInBody(
        const CheckInPrivateHouse(hostName: 'Carmen', hostAddress: 'Zone 3'),
      ),
      {'host_name': 'Carmen', 'host_address': 'Zone 3'},
    );
  });

  testWidgets('Add a new family works offline: queued with client_ref', (
    tester,
  ) async {
    final db = StaffDatabase.forExecutor(NativeDatabase.memory());
    addTearDown(db.close);
    final offline = ConnectivityService.forTesting(
      hasInterface: () async => false,
      probe: () async => false,
      resultCacheTtl: Duration.zero,
    );
    final outbox = OutboxRepository(db, FakeStaffApi(), offline, 4);
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(720, 3000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      testApp(
        const FamiliesToEvacuatePage(),
        overrides: [
          ...signedInAs(official),
          staffReadCacheProvider.overrideWithValue(
            FakeReadCache({...homeAnswers, '/families-to-evacuate': _answer}),
          ),
          evacuationEventsLookupProvider.overrideWith((ref) async => const []),
          outboxRepositoryProvider.overrideWithValue(outbox),
          pendingActionsProvider.overrideWith((ref) {
            ref.watch(outboxRevisionProvider);
            return outbox.getAll();
          }),
          staffSyncAllProvider.overrideWith(_NoSync.new),
          connectivityServiceProvider.overrideWithValue(offline),
          puroksForBarangayProvider.overrideWith((ref, id) async => const []),
          ownCentersProvider.overrideWith((ref) async => const []),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add family'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New family'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, "Head's first name"),
      'Carla',
    );
    await tester.enterText(
      find.widgetWithText(TextField, "Head's last name"),
      'Santos',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add family'));
    await tester.pumpAndSettle();

    final queued = (await outbox.getAll()).single;
    expect(queued.kind, PendingActionKind.listedFamilyAdd);
    expect(queued.path, '/families-to-evacuate');
    expect(queued.body['head_first_name'], 'Carla');
    expect(queued.body['evacuation_event_id'], isNotNull);
    expect(queued.body['client_ref'], queued.localId);
    expect(find.text('Added on this phone, waiting to sync'), findsOneWidget);
    expect(
      find.text('Add Carla Santos to the families to evacuate'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    offline.dispose();
    await tester.pump(const Duration(seconds: 10));
  });

  test('a past family already on the list counts as added', () {
    expect(
      PendingActionKind.listedFamilyAdd.alreadyHappened!.matches(422, {
        'message': 'This family is already on your list.',
        'errors': {
          'source_family_id': ['This family is already on your list.'],
        },
      }),
      isTrue,
    );
  });

  testWidgets('Check in with one tap works offline through the queue', (
    tester,
  ) async {
    final db = StaffDatabase.forExecutor(NativeDatabase.memory());
    addTearDown(db.close);
    final offline = ConnectivityService.forTesting(
      hasInterface: () async => false,
      probe: () async => false,
      resultCacheTtl: Duration.zero,
    );
    final outbox = OutboxRepository(db, FakeStaffApi(), offline, 4);
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(720, 3000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      testApp(
        const FamiliesToEvacuatePage(),
        overrides: [
          ...signedInAs(official),
          staffReadCacheProvider.overrideWithValue(
            FakeReadCache({...homeAnswers, '/families-to-evacuate': _answer}),
          ),
          evacuationEventsLookupProvider.overrideWith((ref) async => const []),
          outboxRepositoryProvider.overrideWithValue(outbox),
          pendingActionsProvider.overrideWith((ref) {
            ref.watch(outboxRevisionProvider);
            return outbox.getAll();
          }),
          staffSyncAllProvider.overrideWith(_NoSync.new),
          connectivityServiceProvider.overrideWithValue(offline),
          puroksForBarangayProvider.overrideWith((ref, id) async => const []),
          ownCentersProvider.overrideWith(
            (ref) async => const [
              OwnCenter(
                center: EvacuationCenterLookup(
                  id: 12,
                  name: 'Binatagan Hall',
                  barangayId: 13,
                  status: 'active',
                ),
              ),
              OwnCenter(
                center: EvacuationCenterLookup(
                  id: 14,
                  name: 'New Chapel',
                  barangayId: 13,
                  status: 'active',
                  approvalStatus: 'pending',
                ),
              ),
            ],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Families to evacuate'), findsOneWidget);
    expect(find.text('High risk'), findsOneWidget);
    expect(find.text('CHECKED IN'), findsWidgets);

    // Maria Santos (high-risk Purok 3) is first.
    await tester.tap(find.widgetWithText(FilledButton, 'Check in').first);
    await tester.pumpAndSettle();
    expect(find.text('Check in Maria Santos'), findsOneWidget);
    expect(find.text('Pending CSWD approval'), findsOneWidget);
    await tester.tap(find.text('Binatagan Hall'));
    await tester.pumpAndSettle();

    final queued = (await outbox.getAll()).single;
    expect(queued.kind, PendingActionKind.familyCheckIn);
    expect(queued.path, '/families-to-evacuate/2/check-in');
    expect(queued.body['evacuation_center_id'], 12);
    expect(queued.body['client_ref'], queued.localId);
    await tester.pumpAndSettle();
    expect(find.text('Waiting to sync'), findsOneWidget);
    // Let the snack bar run out and stop the offline re-check.
    await tester.pumpWidget(const SizedBox());
    offline.dispose();
    await tester.pump(const Duration(seconds: 10));
  });
}
