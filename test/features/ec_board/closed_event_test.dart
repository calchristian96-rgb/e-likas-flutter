import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elikas_mobile/app/theme/app_theme.dart';
import 'package:elikas_mobile/core/error/failure.dart';
import 'package:elikas_mobile/core/localization/framework_localizations_fallback.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/age_bracket.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/pending_ec_board_entry.dart';
import 'package:elikas_mobile/features/ec_board/presentation/pages/ec_board_page.dart';
import 'package:elikas_mobile/features/ec_board/presentation/providers/ec_board_provider.dart';
import 'package:elikas_mobile/features/evacuation_centers/domain/entities/evacuation_center.dart';
import 'package:elikas_mobile/features/evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/lookup_entities.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/pending_registration_status.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/lookup_providers.dart';
import 'package:elikas_mobile/features/home/presentation/providers/home_provider.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';

/// A closed event takes no new evacuees (the server refuses them). On the
/// board it stays listed, marked closed, only while entries for it wait on
/// this phone -- and then there's no Add Evacuee, just why.
const _centerId = 5;
const _open = EvacuationEventLookup(
  id: 13,
  name: 'Mayon Alert Level 2',
  status: 'monitoring',
);
const _closed = EvacuationEventLookup(
  id: 11,
  name: 'Tropical Storm Amang',
  status: 'closed',
);
const _older = EvacuationEventLookup(
  id: 9,
  name: 'Typhoon Kristine',
  status: 'closed',
);

PendingEcBoardEntrySummary _waiting(int eventId) => PendingEcBoardEntrySummary(
  localId: 'w$eventId',
  evacuationCenterId: _centerId,
  evacuationEventId: eventId,
  status: PendingRegistrationStatus.needsAttention,
  sex: 'female',
  ageBracket: AgeBracket.adult,
  householdLabel: 'Late Family',
  createdAt: DateTime(2026, 10, 4),
  updatedAt: DateTime(2026, 10, 4),
);

Future<void> _pump(
  WidgetTester tester, {
  required List<EvacuationEventLookup> events,
  List<PendingEcBoardEntrySummary> pending = const [],
}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(360 * 3, 3200 * 3);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        evacuationEventsLookupProvider.overrideWith((ref) async => events),
        for (final e in events)
          ecBoardQuickCountProvider(
            _centerId,
            e.id,
          ).overrideWith((ref) async => throw const NetworkFailure('offline')),
        ecBoardEntriesForCenterProvider(
          _centerId,
        ).overrideWith((ref) async => pending),
        centerByIdProvider(_centerId).overrideWith(
          (ref) async => const EvacuationCenter(
            id: _centerId,
            name: 'Bacong Multipurpose Gymnasium',
            type: 'gym',
            barangay: 'Bacong',
            latitude: 13.2,
            longitude: 123.5,
            capacityPersons: 155,
            status: 'active',
          ),
        ),
        connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          FallbackMaterialLocalizationsDelegate(),
          FallbackCupertinoLocalizationsDelegate(),
          FallbackWidgetsLocalizationsDelegate(),
        ],
        home: const EcBoardPage(centerId: _centerId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<List<String>> _eventChoices(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<int>));
  await tester.pumpAndSettle();
  final items = tester
      .widgetList<DropdownMenuItem<int>>(find.byType(DropdownMenuItem<int>))
      .map((i) => ((i.child as Text).data ?? ''))
      .toSet()
      .toList();
  return items;
}

const _closedNote =
    'This event is closed. Evacuees can no longer be added to it.';

void main() {
  testWidgets('a closed event with nothing waiting is not offered', (
    tester,
  ) async {
    await _pump(tester, events: const [_open, _closed]);

    expect(await _eventChoices(tester), ['Mayon Alert Level 2']);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Add Evacuee'), findsWidgets);
    expect(find.textContaining(_closedNote), findsNothing);
  });

  testWidgets(
    'a closed event stays listed, marked closed, while entries for it '
    'wait; on it there is no Add Evacuee, just why',
    (tester) async {
      await _pump(
        tester,
        events: const [_open, _closed],
        pending: [_waiting(11)],
      );

      // Opens on the open event.
      expect(find.text('Add Evacuee'), findsWidgets);
      expect(
        await _eventChoices(tester),
        containsAll(['Mayon Alert Level 2', 'Tropical Storm Amang (closed)']),
      );
      await tester.tap(find.text('Tropical Storm Amang (closed)').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('closed-event-note')), findsOneWidget);
      expect(
        find.text(
          "$_closedNote Entries still waiting on this phone for it can't sync. "
          'Check them, then delete them from this phone.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Add Evacuee'), findsNothing);
      expect(find.text('Late Family'), findsOneWidget);
    },
  );

  testWidgets('with no open event, past boards can still be looked at, '
      'without Add Evacuee', (tester) async {
    await _pump(tester, events: const [_closed, _older]);

    expect(find.text(_closedNote), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add Evacuee'), findsNothing);
    expect(
      await _eventChoices(tester),
      containsAll([
        'Tropical Storm Amang (closed)',
        'Typhoon Kristine (closed)',
      ]),
    );
  });
}
