import 'package:elikas_mobile/core/cache/staff_read_cache.dart';
import 'package:elikas_mobile/features/box_relief/round_families_page.dart';
import 'package:elikas_mobile/features/outbox/presentation/outbox_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_auth.dart';
import '../../helpers/home_fixtures.dart';

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
    expect(find.text('Give a box to Cruz now?'), findsOneWidget);
    expect(
      find.text('2 families with a higher priority are still waiting.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Give a box to Cruz now?'), findsNothing);
  });

  testWidgets(
    'priority label; a family from another barangay is given its box here; '
    'ours staying elsewhere is given by the host',
    (tester) async {
      final families = roundFamilies();
      final purok = (families['puroks'] as List).first as Map<String, dynamic>;
      purok['families'] = [
        roundFamily(1, 'Reyes', priority: 'PWD / senior', nextInLine: true),
        {
          ...roundFamily(2, 'Dela Cruz', order: 2),
          'from_barangay': {'id': 49, 'name': 'Tomolin'},
        },
        {
          ...roundFamily(3, 'Bautista', order: 3),
          'staying_in': {'id': 49, 'name': 'Tomolin'},
          'may_give': false,
        },
      ];
      await _pump(tester, families);
      expect(find.textContaining('Priority: PWD / senior'), findsOneWidget);
      expect(find.textContaining('From Tomolin'), findsOneWidget);
      expect(
        find.text('Staying in Tomolin: they give the box'),
        findsOneWidget,
      );
      // Reyes (next in line) and Dela Cruz can be given; Bautista cannot.
      expect(find.text('Give box'), findsNWidgets(2));
    },
  );
}
