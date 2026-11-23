import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/network/staff_api_client.dart';
import 'package:elikas_mobile/core/widgets/ui_kit.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/family_here.dart';
import 'package:elikas_mobile/features/ec_board/presentation/pages/ec_board_page.dart';
import 'package:elikas_mobile/features/ec_board/presentation/providers/ec_board_provider.dart';
import 'package:elikas_mobile/features/ec_board/presentation/widgets/families_here_section.dart';
import 'package:elikas_mobile/features/evacuation_centers/domain/entities/evacuation_center.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/lookup_entities.dart';
import 'package:elikas_mobile/features/staff_evacuation_centers/presentation/providers/own_centers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';
import '../../helpers/fake_staff_auth.dart';
import '../../helpers/home_fixtures.dart';

EvacuationCenter _center(int occupancy, {String source = 'official'}) =>
    EvacuationCenter(
      id: 12,
      name: 'Binatagan Hall',
      type: 'barangay_hall',
      latitude: 13.2,
      longitude: 123.5,
      capacityPersons: 100,
      capacitySource: source,
      currentOccupancy: occupancy,
      occupancyPercent: occupancy.toDouble(),
      status: 'active',
    );

void main() {
  test('"Ask another center for space" from 90% of a known capacity', () {
    expect(askForSpaceAt(_center(89)), isFalse);
    expect(askForSpaceAt(_center(90)), isTrue);
    expect(askForSpaceAt(_center(95, source: 'estimated')), isTrue);
    expect(askForSpaceAt(_center(95, source: 'unknown')), isFalse);
  });

  testWidgets(
    'a family here: Check out and Transfer to another of our centers',
    (tester) async {
      final api = FakeStaffApi();
      await tester.pumpWidget(
        testApp(
          const Scaffold(
            body: SingleChildScrollView(
              child: FamiliesHereSection(centerId: 12, evacuationEventId: 24),
            ),
          ),
          overrides: [
            ...homeOverrides(official),
            staffApiClientProvider.overrideWithValue(api),
            connectivityServiceProvider.overrideWithValue(
              ConnectivityService.forTesting(
                hasInterface: () async => true,
                probe: () async => true,
              ),
            ),
            ecBoardFamiliesHereProvider(12, 24).overrideWith(
              (ref) async => const [
                FamilyHere(
                  id: 5669,
                  isGeneric: false,
                  name: 'Maria Santos',
                  memberCount: 4,
                  headLinked: true,
                ),
              ],
            ),
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
                    id: 15,
                    name: 'Binatagan Chapel',
                    barangayId: 13,
                    status: 'active',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MoreButton));
      await tester.pumpAndSettle();
      expect(find.text('Check out'), findsOneWidget);
      await tester.tap(find.text('Transfer'));
      await tester.pumpAndSettle();
      expect(find.text('Transfer Maria Santos'), findsOneWidget);
      expect(find.text('Ask another barangay\'s center'), findsWidgets);
      await tester.tap(find.text('Binatagan Chapel'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Move'));
      await tester.pumpAndSettle();
      expect(api.calls, contains('PATCH /families/5669/evacuation-center'));
      expect(api.bodies.last, {'evacuation_center_id': 15});
    },
  );
}
