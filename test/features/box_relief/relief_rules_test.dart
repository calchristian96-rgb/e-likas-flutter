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
    expect(find.widgetWithText(FilledButton, 'Give box'), findsNWidgets(3));
    expect(find.text('Waiting for more boxes'), findsNothing);
  });

  testWidgets('no box left: Waiting for more boxes, disabled', (tester) async {
    await _pump(tester, roundFamilies(received: 1, given: 1));
    final waiting = find.widgetWithText(FilledButton, 'Waiting for more boxes');
    expect(waiting, findsNWidgets(3));
    expect(tester.widget<FilledButton>(waiting.first).onPressed, isNull);
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
      find.descendant(of: cruz, matching: find.byType(FilledButton)),
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
}
