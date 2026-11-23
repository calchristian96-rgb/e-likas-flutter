import 'package:elikas_mobile/features/count_submissions/final_count_card.dart';
import 'package:elikas_mobile/features/outbox/presentation/outbox_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_auth.dart';

/// GET /count-submissions/computed after a validated submission, with
/// three families registered since (backend 5bb30d1).
Map<String, dynamic> _computed({Map<String, dynamic>? late}) => {
  'evacuation_event': {'id': 24, 'name': 'Typhoon Pepito', 'status': 'active'},
  'barangay': {'id': 13, 'name': 'Binatagan'},
  'computed': {
    'families': 45,
    'families_inside_ec': 40,
    'families_outside_ec': 5,
    'persons': 161,
    'persons_inside_ec': 143,
    'persons_outside_ec': 18,
  },
  'late_entries': late,
  'checks': {'incomplete_families': 1, 'possible_duplicates': 0},
  'current_submission': {
    'id': 41,
    'version': 1,
    'status': 'validated',
    'families': 42,
    'families_inside_ec': 38,
    'families_outside_ec': 4,
    'persons': 150,
    'persons_inside_ec': 134,
    'persons_outside_ec': 16,
    'submitted_at': '2026-11-17T06:00:00+00:00',
    'reviewed_at': '2026-11-17T07:00:00+00:00',
  },
  'validated_need': {'families': 42, 'persons': 150},
  'has_official_account': true,
};

const _late = {
  'since': '2026-11-17T06:00:00+00:00',
  'submission_id': 41,
  'submission_status': 'validated',
  'families': 3,
  'persons': 11,
  'removed_families': 0,
  'removed_persons': 0,
  'total': 3,
};

Future<void> _pump(WidgetTester tester, Map<String, dynamic> json) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(720, 2400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    testApp(
      const Scaffold(body: SingleChildScrollView(child: FinalCountCard())),
      overrides: [
        ...signedInAs(official),
        computedCountProvider.overrideWith(
          (ref) async => (
            count: ComputedCount.fromJson(json),
            fetchedAt: DateTime(2026, 11, 17, 16),
            fromCache: false,
          ),
        ),
        pendingActionsProvider.overrideWith((ref) async => const []),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('late entries and checks are read; none before a submission', () {
    final c = ComputedCount.fromJson(_computed(late: _late));
    expect(c.hasLateEntries, isTrue);
    expect(c.lateEntries!.families, 3);
    expect(c.lateEntries!.persons, 11);
    expect(c.checks.incompleteFamilies, 1);
    expect(c.validatedFamilies, 42);
    expect(ComputedCount.fromJson(_computed()).hasLateEntries, isFalse);
  });

  testWidgets('validated stays as it was; late entries shown apart', (
    tester,
  ) async {
    await _pump(tester, _computed(late: _late));
    // The validated count and its time (Manila), never the live 45.
    expect(
      find.text('Validated: 42 families, report as of Nov 17, 3:00 PM'),
      findsOneWidget,
    );
    expect(find.text('3 late entries'), findsOneWidget);
    expect(find.text('Added: 3 families, 11 persons'), findsOneWidget);
    // Shown as chips (0.4.0 Part 9).
    expect(find.text('since Nov 17, 2:00 PM'), findsOneWidget);
    expect(find.byType(Chip), findsNWidgets(2));
    expect(
      find.textContaining('validated count, which never changes'),
      findsOneWidget,
    );
    expect(find.text('Submit updated count'), findsOneWidget);
  });

  testWidgets('the submit dialog: centers, private houses, checks, next', (
    tester,
  ) async {
    await _pump(tester, _computed(late: _late));
    await tester.tap(find.text('Submit updated count'));
    await tester.pumpAndSettle();
    expect(
      find.text('In centers: 40 families · In private houses: 5 families'),
      findsOneWidget,
    );
    expect(
      find.text('Check: 1 family has incomplete details.'),
      findsOneWidget,
    );
    expect(
      find.text('After this, new evacuees are marked as late entries.'),
      findsOneWidget,
    );
    expect(find.text('Review first'), findsOneWidget);
    await tester.tap(find.text('Review first'));
    await tester.pumpAndSettle();
    expect(find.text('Review first'), findsNothing);
  });
}
