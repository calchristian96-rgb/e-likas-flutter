import 'package:elikas_mobile/features/barangay_status/domain/barangay_status.dart';
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
  testWidgets('barangays evacuating: Evacuation ordered', (tester) async {
    await tester.pumpWidget(
      _card(
        BarangayStatusBoard(
          eventName: 'Typhoon Pepito',
          eventStatus: 'active',
          barangays: [
            _b(1, 'preemptive_evacuation'),
            _b(2, 'forced_evacuation'),
            _b(3, 'watch'),
          ],
        ),
      ),
    );
    expect(find.text('Evacuation ordered'), findsOneWidget);
    expect(
      find.text('2 barangays are under preemptive or forced evacuation.'),
      findsOneWidget,
    );
    expect(find.text('Normal Monitoring'), findsNothing);
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
    expect(find.text('Normal Monitoring'), findsOneWidget);
  });
}
