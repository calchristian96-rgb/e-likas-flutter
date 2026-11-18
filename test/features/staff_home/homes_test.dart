import 'package:elikas_mobile/features/barangay_status/domain/barangay_status.dart';
import 'package:elikas_mobile/features/barangay_status/presentation/barangay_status_card.dart';
import 'package:elikas_mobile/features/barangay_status/presentation/barangay_status_providers.dart';
import 'package:elikas_mobile/features/home/presentation/widgets/hotlines_quick_card.dart';
import 'package:elikas_mobile/features/staff_home/staff_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_auth.dart';
import '../../helpers/home_fixtures.dart';

class _Chosen extends ResidentBarangayNotifier {
  @override
  ResidentBarangay? build() =>
      const ResidentBarangay(id: 13, name: 'Binatagan');
}

Future<void> _pumpTall(WidgetTester tester, Widget app) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(720, 4000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the barangay official home: status, numbers, buttons, to do', (
    tester,
  ) async {
    await _pumpTall(
      tester,
      testApp(const StaffHomePage(), overrides: homeOverrides(official)),
    );

    expect(find.text('Event: Typhoon Pepito'), findsOneWidget);
    // Status with the quick buttons it may still switch to.
    expect(find.text('Flooding reported'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Watch'), findsOneWidget);
    // Evacuees in my centers, families without a box, boxes left.
    expect(find.text('380'), findsOneWidget);
    expect(find.text('Families without a box'), findsOneWidget);
    expect(find.text('Boxes left'), findsOneWidget);
    // The three big buttons.
    expect(find.text('Register family'), findsOneWidget);
    expect(find.text('Check in / Check out'), findsOneWidget);
    expect(find.text('Give relief box'), findsOneWidget);
    // To do: 3 of the 4 families have no box yet.
    expect(find.text('3 families are waiting for boxes'), findsOneWidget);
    expect(find.text('3 waiting to send'), findsOneWidget);
  });

  testWidgets('the sync chip says All sent when nothing waits', (tester) async {
    await _pumpTall(
      tester,
      testApp(
        const StaffHomePage(),
        overrides: homeOverrides(official, waiting: 0),
      ),
    );
    expect(find.text('All sent'), findsOneWidget);
  });

  testWidgets('the CSWDO home: totals, statuses, warnings, web note', (
    tester,
  ) async {
    await _pumpTall(
      tester,
      testApp(const StaffHomePage(), overrides: homeOverrides(cswd)),
    );

    expect(find.text('City overview'), findsOneWidget);
    expect(find.text('412'), findsOneWidget);
    expect(find.text('Forced evacuation: 1'), findsOneWidget);
    expect(find.text('Ligao West Central School is 95% full'), findsOneWidget);
    expect(find.text('Tuburan is short 12 boxes'), findsOneWidget);
    expect(
      find.text('Final count not sent: 1 barangay (Paulba)'),
      findsOneWidget,
    );
    expect(find.textContaining('do this on the web'), findsOneWidget);
    // GET /dashboard/city actions.transfer_requests_pending.
    expect(find.text('2 transfer requests waiting'), findsOneWidget);
    // Unread notifications on the bell.
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('2')),
      findsOneWidget,
    );
    // Not the official's buttons.
    expect(find.text('Register family'), findsNothing);
  });

  testWidgets("the resident home's status card says what to do", (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        const Scaffold(body: BarangayStatusCard()),
        overrides: [
          residentBarangayProvider.overrideWith(_Chosen.new),
          barangayStatusBoardProvider.overrideWith(
            (ref) async => const BarangayStatusBoard(
              eventName: 'Typhoon Pepito',
              eventStatus: 'active',
              barangays: [
                BarangayStatus(
                  id: 13,
                  name: 'Binatagan',
                  status: 'preemptive_evacuation',
                  label: 'Preemptive evacuation',
                ),
              ],
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Preemptive evacuation'), findsOneWidget);
    expect(
      find.text('Preemptive evacuation: go to your evacuation center now.'),
      findsOneWidget,
    );
  });

  testWidgets('the resident home lists hotlines with a call button', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const Scaffold(body: HotlinesQuickCard())));
    await tester.pumpAndSettle();
    expect(find.text('911'), findsOneWidget);
    expect(find.byIcon(Icons.call), findsNWidgets(3));
    expect(find.text('All hotlines'), findsOneWidget);
  });
}
