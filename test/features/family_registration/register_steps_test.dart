// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:convert';

import 'package:elikas_mobile/features/family_registration/domain/entities/family_registration_draft.dart';
import 'package:elikas_mobile/features/family_registration/domain/repositories/pending_queue_repository.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/pending_queue_provider.dart';
import 'package:elikas_mobile/features/family_registration/presentation/register/register_family_page.dart';
import 'package:elikas_mobile/features/outbox/domain/pending_action.dart';
import 'package:elikas_mobile/features/outbox/presentation/outbox_providers.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/lookup_entities.dart';
import 'package:elikas_mobile/features/staff_shell/current_event.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_staff_auth.dart';
import '../../helpers/register_fixtures.dart';

/// Register family in steps (Part 2.6): 1 Head of family, 2 Members,
/// 3 Purok and center, 4 Review, then Save queues it.
class _Queue implements PendingQueueRepository {
  final saved = <FamilyRegistrationDraft>[];

  @override
  Future<String> enqueue(FamilyRegistrationDraft draft) async {
    saved.add(draft);
    return 'local-1';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoSync extends StaffSyncAll {
  _NoSync(super.ref);

  @override
  Future<OutboxRunResult> call({bool automatic = true}) async =>
      const OutboxRunResult();
}

FilledButton _primary(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton).last);

Future<_Queue> _pump(
  WidgetTester tester, {
  Object? draft,
  List<Override> extra = const [],
}) async {
  SharedPreferences.setMockInitialValues({
    if (draft != null) 'elikas.registerDraft.4': jsonEncode(draft),
  });
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(720, 2400);
  addTearDown(tester.view.reset);
  final queue = _Queue();
  await tester.pumpWidget(
    testApp(
      const RegisterFamilyPage(),
      overrides: [
        ...registerOverrides,
        pendingQueueRepositoryProvider.overrideWithValue(queue),
        staffSyncAllProvider.overrideWith(_NoSync.new),
        ...extra,
      ],
    ),
  );
  await tester.pumpAndSettle();
  return queue;
}

void main() {
  testWidgets('step 1 waits for the head of family', (tester) async {
    await _pump(tester);
    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(find.text('Head of family'), findsWidgets);
    expect(_primary(tester).onPressed, isNull);
  });

  testWidgets('a saved draft walks the four steps and is queued on Save', (
    tester,
  ) async {
    final queue = await _pump(tester, draft: registerDraft);
    for (final (step, title) in const [
      (1, 'Head of family'),
      (2, 'Members'),
      (3, 'Purok and center'),
      (4, 'Review'),
    ]) {
      expect(find.text('Step $step of 4'), findsOneWidget);
      expect(find.text(title), findsWidgets);
      if (step < 4) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
    }
    expect(find.textContaining('Ana'), findsWidgets);
    expect(find.textContaining('Binatagan Elementary School'), findsWidgets);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saved = queue.saved.single;
    expect(saved.evacuationEventId, 24);
    expect(saved.barangayId, 13);
    expect(saved.evacuationCenterId, 71);
    expect(saved.purokId, 7);
    expect(saved.displacementType, 'inside_center');
    expect(saved.members, hasLength(2));
  });

  testWidgets('no event at all: the backend\'s words, nothing to fill in', (
    tester,
  ) async {
    await _pump(
      tester,
      extra: [currentStaffEventProvider.overrideWith((ref) async => null)],
    );
    expect(
      find.text(
        'No open event yet. CSWDO opens an event when a threat is announced.',
      ),
      findsOneWidget,
    );
    expect(find.text('Next'), findsNothing);
  });

  testWidgets(
    'a Monitoring event: registering waits for Start evacuation (lock)',
    (tester) async {
      final queue = await _pump(
        tester,
        draft: registerDraft,
        extra: [
          currentStaffEventProvider.overrideWith(
            (ref) async => const EvacuationEventLookup(
              id: 30,
              name: 'Typhoon Rolly',
              status: 'monitoring',
            ),
          ),
        ],
      );
      expect(find.text('Available when the event is Active'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
      expect(queue.saved, isEmpty);
    },
  );

  testWidgets('a closed selected event: read-only, nothing to save', (
    tester,
  ) async {
    await _pump(
      tester,
      draft: registerDraft,
      extra: [
        currentStaffEventProvider.overrideWith(
          (ref) async => const EvacuationEventLookup(
            id: 60,
            name: 'Typhoon Kristine',
            status: 'closed',
          ),
        ),
      ],
    );
    expect(
      find.textContaining('"Typhoon Kristine" is closed.'),
      findsOneWidget,
    );
    expect(find.text('Next'), findsNothing);
  });

  testWidgets('a private house: host name and purok, no center sent', (
    tester,
  ) async {
    final queue = await _pump(tester, draft: registerDraft);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Where is the family staying?'), findsOneWidget);

    await tester.tap(find.text('Private house'));
    await tester.pumpAndSettle();
    // No host yet: Next waits.
    expect(_primary(tester).onPressed, isNull);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name of the relative or friend'),
      'Carmen Reyes',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Address of the house'),
      'Zone 3, near the chapel',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Private house, with Carmen Reyes'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final json = queue.saved.single.toJson();
    expect(json['displacement_type'], 'outside_center');
    expect(json['host_name'], 'Carmen Reyes');
    expect(json['host_address'], 'Zone 3, near the chapel');
    expect(json.containsKey('evacuation_center_id'), isFalse);
  });
}
