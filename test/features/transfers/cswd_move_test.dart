import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/network/staff_api_client.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/family_here.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/lookup_entities.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/lookup_providers.dart';
import 'package:elikas_mobile/features/home/presentation/providers/home_provider.dart';
import 'package:elikas_mobile/features/transfers/cswd_move_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';
import '../../helpers/fake_staff_auth.dart';

class _Online implements ConnectivityService {
  _Online(this.online);
  final bool online;

  @override
  Future<bool> get hasConnection async => online;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _family = FamilyHere(
  id: 5669,
  isGeneric: false,
  memberCount: 4,
  hereCount: 4,
  headLinked: true,
  name: 'Bea Bituin',
  barangayName: 'Binatagan',
);

Future<FakeStaffApi> _pump(WidgetTester tester, {bool online = true}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(720, 3000);
  addTearDown(tester.view.reset);
  final api = FakeStaffApi();
  await tester.pumpWidget(
    testApp(
      const CswdMovePage(
        family: _family,
        fromCenterId: 71,
        fromCenterName: 'LWCES (B)',
        eventId: 24,
      ),
      overrides: [
        ...signedInAs(cswd),
        staffApiClientProvider.overrideWithValue(api),
        connectivityServiceProvider.overrideWithValue(_Online(online)),
        connectivityStatusProvider.overrideWith((ref) => Stream.value(online)),
        barangaysProvider.overrideWith(
          (ref) async => const [
            Barangay(id: 13, name: 'Binatagan'),
            Barangay(id: 49, name: 'Tomolin'),
          ],
        ),
        evacuationCentersLookupProvider.overrideWith(
          (ref) async => const [
            EvacuationCenterLookup(
              id: 71,
              name: 'LWCES (B)',
              barangayId: 13,
              status: 'full',
            ),
            EvacuationCenterLookup(
              id: 141,
              name: 'DA Building',
              barangayId: 49,
              status: 'open',
            ),
            EvacuationCenterLookup(
              id: 150,
              name: 'Closed Chapel',
              barangayId: 49,
              status: 'closed',
            ),
          ],
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return api;
}

void main() {
  testWidgets('any center, a reason required, a confirm, then PATCH', (
    tester,
  ) async {
    final api = await _pump(tester);
    // Not the center it is at, not a closed one.
    expect(find.text('DA Building'), findsOneWidget);
    expect(find.text('Closed Chapel'), findsNothing);
    final move = find.widgetWithText(FilledButton, 'Move');

    await tester.tap(find.text('DA Building'));
    await tester.pumpAndSettle();
    // No reason yet.
    expect(tester.widget<FilledButton>(move).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'Own school is full');
    await tester.pumpAndSettle();
    await tester.tap(move);
    await tester.pumpAndSettle();
    expect(find.text('Move Bea Bituin?'), findsWidgets);
    expect(
      find.text('1 family (4 persons) from LWCES (B) to DA Building'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Move').last);
    await tester.pumpAndSettle();
    expect(api.calls, contains('PATCH /families/5669/evacuation-center'));
    expect(api.bodies.last, {
      'evacuation_center_id': 141,
      'reason': 'Own school is full',
    });
  });

  testWidgets('offline: Move stays off', (tester) async {
    final api = await _pump(tester, online: false);
    await tester.tap(find.text('DA Building'));
    await tester.enterText(find.byType(TextField).first, 'Own school is full');
    await tester.pumpAndSettle();
    final move = find.widgetWithText(FilledButton, 'Move');
    expect(tester.widget<FilledButton>(move).onPressed, isNull);
    expect(find.textContaining('Needs a connection.'), findsOneWidget);
    expect(api.calls, isEmpty);
  });
}
