import 'package:elikas_mobile/features/barangay_status/domain/barangay_status.dart';
import 'package:elikas_mobile/features/barangay_status/presentation/barangay_status_providers.dart';
import 'package:elikas_mobile/features/barangay_status/presentation/bulletin_strip.dart';
import 'package:elikas_mobile/features/home/presentation/widgets/emergency_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_auth.dart';

BarangayStatus _b(int id, String status) =>
    BarangayStatus(id: id, name: 'B$id', status: status, label: status);

Widget _card(BarangayStatusBoard? board) => testApp(
  Scaffold(
    body: EmergencyStatusCard(
      latestAlert: null,
      isLoading: false,
      situation: board,
    ),
  ),
);

/// With no alert, the top card tells the truth about the barangays
/// instead of "Normal Monitoring" while some evacuate.
void main() {
  final board = BarangayStatusBoard(
    eventName: 'Typhoon Pepito',
    eventStatus: 'active',
    barangays: [
      _b(1, 'preemptive_evacuation'),
      _b(2, 'forced_evacuation'),
      _b(3, 'watch'),
    ],
  );

  testWidgets('barangays evacuating: the card does not repeat it', (
    tester,
  ) async {
    await tester.pumpWidget(_card(board));
    expect(find.text('EVACUATION ORDERED'), findsNothing);
    expect(find.text('NORMAL MONITORING'), findsNothing);
  });

  testWidgets('barangays evacuating: the live strip says it once', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        const Scaffold(body: BulletinStrip()),
        overrides: [
          barangayStatusBoardProvider.overrideWith((ref) async => board),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('EVACUATION ORDERED · Typhoon Pepito'), findsOneWidget);
    expect(
      find.text('2 barangays are under preemptive or forced evacuation.'),
      findsOneWidget,
    );
  });

  testWidgets('a calm day: no live strip at all', (tester) async {
    await tester.pumpWidget(
      testApp(
        const Scaffold(body: BulletinStrip()),
        overrides: [
          barangayStatusBoardProvider.overrideWith(
            (ref) async => BarangayStatusBoard(
              eventName: 'Typhoon Pepito',
              eventStatus: 'monitoring',
              barangays: [_b(1, 'watch')],
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('EVACUATION ORDERED'), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('an open event, nobody evacuating: monitored', (tester) async {
    await tester.pumpWidget(
      _card(
        BarangayStatusBoard(
          eventName: 'Typhoon Pepito',
          eventStatus: 'monitoring',
          barangays: [_b(1, 'normal')],
        ),
      ),
    );
    expect(find.text('No barangay has to evacuate.'), findsOneWidget);
  });

  testWidgets('no open event: Normal Monitoring', (tester) async {
    await tester.pumpWidget(_card(const BarangayStatusBoard(barangays: [])));
    expect(find.text('NORMAL MONITORING'), findsOneWidget);
  });
}
