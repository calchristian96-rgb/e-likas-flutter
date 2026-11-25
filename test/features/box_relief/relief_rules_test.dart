import 'package:elikas_mobile/core/cache/staff_read_cache.dart';
import 'package:elikas_mobile/features/box_relief/round_families_page.dart';
import 'package:elikas_mobile/features/outbox/presentation/outbox_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_auth.dart';
import '../../helpers/home_fixtures.dart';
import 'package:drift/native.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/database/staff_database.dart';
import 'package:elikas_mobile/features/outbox/data/outbox_repository.dart';
import 'package:elikas_mobile/features/outbox/domain/pending_action.dart';
import '../../helpers/fake_staff_api.dart';

/// Relief rules (Part 1.5): give while boxes are left even if the round
/// is short; none left means "Waiting for more boxes"; the first family
/// is "Next in line"; giving out of the priority order asks first.
Future<void> _pump(WidgetTester tester, Map<String, dynamic> families) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(720, 3000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    testApp(
      const RoundFamiliesPage(roundId: 1),
      overrides: [
        ...signedInAs(official),
        staffReadCacheProvider.overrideWithValue(
          FakeReadCache({'/box-relief/rounds/1/families': families}),
        ),
        pendingActionsProvider.overrideWith((ref) async => const []),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

class _NoSync extends StaffSyncAll {
  _NoSync(super.ref);

  @override
  Future<OutboxRunResult> call({bool automatic = true}) async =>
      const OutboxRunResult();
}

void main() {
  testWidgets('boxes left: Give box, the first family is Next in line', (
    tester,
  ) async {
    await _pump(tester, roundFamilies());
    expect(
      find.text('Priority order: give to the families at the top first.'),
      findsOneWidget,
    );
    expect(find.textContaining('Next in line'), findsOneWidget);
    // Only the next family in line gets the primary Give button.
    expect(find.widgetWithText(FilledButton, 'Give box'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Give box'), findsNWidgets(2));
    expect(find.text('Waiting for more boxes'), findsNothing);
  });

  testWidgets('no box left: Waiting for more boxes, disabled', (tester) async {
    await _pump(tester, roundFamilies(received: 1, given: 1));
    final waiting = find.ancestor(
      of: find.text('Waiting for more boxes'),
      matching: find.bySubtype<ButtonStyleButton>(),
    );
    expect(waiting, findsNWidgets(3));
    for (final b in tester.widgetList<ButtonStyleButton>(waiting)) {
      expect(b.onPressed, isNull);
    }
  });

  testWidgets('out of priority order: a warning first, Cancel gives nothing', (
    tester,
  ) async {
    await _pump(tester, roundFamilies());
    final cruz = find.ancestor(
      of: find.text('Cruz'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: cruz, matching: find.byType(OutlinedButton)),
    );
    await tester.pumpAndSettle();
    // apps-api-2026-11-24.md 1.3, word for word.
    expect(find.text('Give a box to this family?'), findsOneWidget);
    expect(
      find.text(
        '2 higher-priority families have not received a box yet. Continue?',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Give a box to this family?'), findsNothing);
  });

  testWidgets(
    'priority label; a family from another barangay is given its box here; '
    'ours staying elsewhere are listed apart, without Give',
    (tester) async {
      final families = roundFamilies();
      final purok = (families['puroks'] as List).first as Map<String, dynamic>;
      purok['families'] = [
        {
          ...roundFamily(
            1,
            'Reyes',
            priority: 'PWD / senior',
            nextInLine: true,
          ),
          'staying_in': {
            'barangay': {'id': 13, 'name': 'Binatagan'},
            'center': {'id': 71, 'name': 'Binatagan Hall'},
            'private_house': false,
            'other_barangay': false,
          },
          'may_give': true,
        },
        {
          ...roundFamily(2, 'Dela Cruz', order: 2),
          'from_barangay': {'id': 49, 'name': 'Tomolin'},
          'staying_in': {
            'barangay': {'id': 13, 'name': 'Binatagan'},
            'center': {'id': 71, 'name': 'Binatagan Hall'},
            'private_house': false,
            'other_barangay': true,
          },
          'may_give': true,
        },
        {
          ...roundFamily(3, 'Santos', order: 3),
          'location': 'outside_center',
          'host_name': 'Juan Reyes',
          'staying_in': {
            'barangay': {'id': 13, 'name': 'Binatagan'},
            'center': null,
            'private_house': true,
            'other_barangay': false,
          },
          'may_give': true,
        },
      ];
      // apps-api-2026-11-24.md 1.1: ours staying in another barangay.
      families['staying_elsewhere'] = [
        {
          'id': 4,
          'name': 'Garcia',
          'head_name': 'Ana Garcia',
          'member_count': 1,
          'purok': {'id': 1, 'name': 'Purok 1'},
          'staying_in': {
            'barangay': {'id': 2, 'name': 'Bay'},
            'center': {'id': 2, 'name': 'Bay Elementary School'},
            'private_house': false,
            'other_barangay': true,
          },
          'gives_box': {'id': 2, 'name': 'Bay'},
          'may_give': false,
          'given': false,
          'given_at': null,
        },
      ];
      await _pump(tester, families);
      expect(find.textContaining('Priority: PWD / senior'), findsOneWidget);
      expect(find.textContaining('From Tomolin'), findsOneWidget);
      expect(find.textContaining('Binatagan Hall'), findsNWidgets(2));
      expect(find.textContaining('Private house (Juan Reyes)'), findsOneWidget);
      // Every family in puroks can be given (staying_in no longer hides it).
      expect(find.text('Give box'), findsNWidgets(3));
      expect(find.text('Staying in another barangay'), findsOneWidget);
      expect(
        find.textContaining('Staying in Bay, Bay Elementary School'),
        findsOneWidget,
      );
      expect(find.textContaining('Bay gives the box'), findsOneWidget);
      expect(find.text('No box yet'), findsOneWidget);
      final garcia = find.ancestor(
        of: find.text('Garcia'),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(of: garcia, matching: find.byType(ButtonStyleButton)),
        findsNothing,
      );
    },
  );

  testWidgets('offline: a give is queued once, with its client_ref', (
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
        const RoundFamiliesPage(roundId: 1),
        overrides: [
          ...signedInAs(official),
          staffReadCacheProvider.overrideWithValue(
            FakeReadCache({'/box-relief/rounds/1/families': roundFamilies()}),
          ),
          outboxRepositoryProvider.overrideWithValue(outbox),
          pendingActionsProvider.overrideWith((ref) {
            ref.watch(outboxRevisionProvider);
            return outbox.getAll();
          }),
          staffSyncAllProvider.overrideWith(_NoSync.new),
          connectivityServiceProvider.overrideWithValue(offline),
        ],
      ),
    );
    await tester.pumpAndSettle();
    // The next family in line: no question asked.
    await tester.tap(find.widgetWithText(FilledButton, 'Give box'));
    await tester.pumpAndSettle();
    expect(find.text('Give a box to this family?'), findsNothing);
    final queued = (await outbox.getAll()).single;
    expect(queued.kind, PendingActionKind.boxHandout);
    expect(queued.path, '/box-relief/rounds/1/handouts');
    expect(queued.body['client_ref'], queued.localId);
    await tester.pumpWidget(const SizedBox());
    offline.dispose();
    await tester.pump(const Duration(seconds: 10));
  });
}
