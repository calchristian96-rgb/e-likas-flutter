import 'package:elikas_mobile/core/cache/staff_read_cache.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/network/staff_api_client.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/family_here.dart';
import 'package:elikas_mobile/features/ec_board/presentation/providers/ec_board_provider.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/lookup_entities.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/lookup_providers.dart';
import 'package:elikas_mobile/features/home/presentation/providers/home_provider.dart';
import 'package:elikas_mobile/features/notifications/notifications.dart';
import 'package:elikas_mobile/features/staff_evacuation_centers/presentation/providers/own_centers_provider.dart';
import 'package:elikas_mobile/features/transfers/transfer_request_page.dart';
import 'package:elikas_mobile/features/transfers/transfers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';
import '../../helpers/fake_staff_auth.dart';
import '../../helpers/home_fixtures.dart';
import '../../helpers/transfer_fixtures.dart';

class _Online implements ConnectivityService {
  _Online(this.online);
  final bool online;

  @override
  Future<bool> get hasConnection async => online;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<FakeStaffApi> _pumpList(
  WidgetTester tester, {
  bool online = true,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(720, 3000);
  addTearDown(tester.view.reset);
  final api = FakeStaffApi();
  await tester.pumpWidget(
    testApp(
      const TransfersPage(),
      overrides: [
        ...signedInAs(official),
        staffReadCacheProvider.overrideWithValue(
          FakeReadCache({
            ...homeAnswers,
            '/transfer-requests': transferRequestsAnswer,
          }),
        ),
        evacuationEventsLookupProvider.overrideWith((ref) async => const []),
        staffApiClientProvider.overrideWithValue(api),
        connectivityServiceProvider.overrideWithValue(_Online(online)),
        connectivityStatusProvider.overrideWith((ref) => Stream.value(online)),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return api;
}

void main() {
  test('a demo request with no requester shows the sending barangay', () {
    final requests = [
      for (final r in transferRequestsAnswer['requests'] as List)
        TransferRequest.fromJson(r as Map<String, dynamic>),
    ];
    final demo = requests.first;
    expect(demo.requestedBy, isNull);
    expect(demo.sender, 'Binatagan');
    expect(demo.isEscalated, isTrue);
    // The receiving side never gets a family id.
    expect(demo.familyList.single.id, isNull);
    expect(requests.last.sender, 'Tomolin Official');
  });

  test('a transfer notification opens Transfers (href only, no id)', () {
    expect(appPathForHref('/transfer-requests'), '/staff/home/transfers');
    expect(appPathForHref('/families/12'), isNull);
    expect(appPathForHref(null), isNull);
  });

  testWidgets(
    'pending, escalated, declined; the receiving side sees heads only',
    (tester) async {
      await _pumpList(tester);
      expect(find.text('From Binatagan'), findsOneWidget);
      expect(find.text('ESCALATED TO CSWD'), findsOneWidget);
      expect(find.text('Bea Bituin: 4 persons'), findsOneWidget);
      // A demo request: "Asked by Binatagan", never "Asked by ,".
      expect(find.textContaining('Asked by Binatagan,'), findsOneWidget);
      expect(find.text('Waiting 41 minutes'), findsOneWidget);
      expect(find.text('Declined'), findsWidgets);
      expect(find.text('Why declined: Our court is full too.'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
    },
  );

  testWidgets('Accept after a confirm dialog', (tester) async {
    final api = await _pumpList(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Accept'));
    await tester.pumpAndSettle();
    expect(find.text('Accept these families?'), findsOneWidget);
    expect(
      find.text('1 family (4 persons) from LWCES (B) to DA Building'),
      findsWidgets,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Accept').last);
    await tester.pumpAndSettle();
    expect(api.calls, contains('POST /transfer-requests/4/accept'));
  });

  testWidgets('Decline needs a reason of at least 3 characters', (
    tester,
  ) async {
    final api = await _pumpList(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Decline'));
    await tester.pumpAndSettle();
    final decline = find.widgetWithText(FilledButton, 'Decline');
    expect(tester.widget<FilledButton>(decline).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'No');
    await tester.pump();
    expect(tester.widget<FilledButton>(decline).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Our hall is full too.');
    await tester.pump();
    await tester.tap(decline);
    await tester.pumpAndSettle();
    expect(api.calls, contains('POST /transfer-requests/4/decline'));
    expect(api.bodies.last, {'reason': 'Our hall is full too.'});
  });

  testWidgets('offline: no Accept or Decline, and why', (tester) async {
    await _pumpList(tester, online: false);
    expect(find.text('Accept'), findsNothing);
    expect(find.text('Decline'), findsNothing);
    expect(find.textContaining('Needs a connection.'), findsOneWidget);
  });

  testWidgets('ask: tick families, choose a center with room, say why, send', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(720, 3000);
    addTearDown(tester.view.reset);
    final api = FakeStaffApi()
      ..getBodies['GET /transfer-requests/suggestions'] = {
        'success': true,
        'data': {
          'from_center': {'id': 71, 'name': 'LWCES (B)', 'barangay_id': 13},
          'persons': 4,
          'centers': [
            {
              'evacuation_center': {'id': 141, 'name': 'DA Building'},
              'barangay': {'id': 49, 'name': 'Tomolin'},
              'distance_km': 2.4,
              'distance_basis': 'center',
              'capacity_persons': 120,
              'capacity_source': 'estimated',
              'remaining_persons': 56,
              'fits': true,
              'capacity_unknown': false,
            },
            {
              'evacuation_center': {'id': 150, 'name': 'Tomolin Chapel'},
              'barangay': {'id': 49, 'name': 'Tomolin'},
              'distance_km': 2.9,
              'distance_basis': 'barangay_centroid',
              'capacity_persons': null,
              'capacity_source': 'unknown',
              'remaining_persons': null,
              'fits': false,
              'capacity_unknown': true,
            },
          ],
        },
      };
    await tester.pumpWidget(
      testApp(
        const TransferRequestPage(centerId: 71, eventId: 24),
        overrides: [
          ...signedInAs(official),
          staffApiClientProvider.overrideWithValue(api),
          connectivityServiceProvider.overrideWithValue(_Online(true)),
          connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
          ownCentersProvider.overrideWith(
            (ref) async => const [
              OwnCenter(
                center: EvacuationCenterLookup(
                  id: 71,
                  name: 'LWCES (B)',
                  barangayId: 13,
                  status: 'full',
                ),
              ),
            ],
          ),
          ecBoardFamiliesHereProvider(71, 24).overrideWith(
            (ref) async => const [
              FamilyHere(
                id: 5669,
                isGeneric: false,
                memberCount: 4,
                hereCount: 4,
                headLinked: true,
                name: 'Bea Bituin',
              ),
              // Another barangay's family: not ours to move.
              FamilyHere(
                id: 9001,
                isGeneric: true,
                memberCount: 2,
                headLinked: true,
              ),
            ],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('From LWCES (B)'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsOneWidget);

    await tester.tap(find.text('Bea Bituin'));
    await tester.pumpAndSettle();
    expect(find.text('Room for 56 (est.)'), findsOneWidget);
    expect(find.text('Tomolin · about 2.9 km'), findsOneWidget);
    expect(find.text('Capacity unknown'), findsOneWidget);

    await tester.tap(find.text('DA Building'));
    await tester.enterText(find.byType(TextField), 'Our hall is full.');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Send request'));
    await tester.pumpAndSettle();
    expect(find.text('Ask Tomolin to take these families?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Send request').last);
    await tester.pumpAndSettle();

    expect(api.calls, contains('POST /transfer-requests'));
    expect(api.bodies.last, {
      'evacuation_event_id': 24,
      'family_ids': [5669],
      'to_center_id': 141,
      'note': 'Our hall is full.',
    });
  });
}
