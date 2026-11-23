import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/network/staff_api_client.dart';
import 'package:elikas_mobile/features/notifications/notifications.dart';
import 'package:elikas_mobile/features/staff_home/barangay_dashboard.dart';
import 'package:elikas_mobile/features/staff_home/staff_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';
import '../../helpers/fake_staff_auth.dart';
import '../../helpers/home_fixtures.dart';

Future<void> _pumpTall(WidgetTester tester, Widget app) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(720, 4000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

/// A practice event being monitored: named like a real one.
const _monitored = {
  'id': 24,
  'name': 'Incoming Typhoon',
  'status': 'monitoring',
  'is_demo': true,
};

void main() {
  testWidgets('Monitoring: one lock design, Families are arriving tells CSWD', (
    tester,
  ) async {
    final api = FakeStaffApi();
    await _pumpTall(
      tester,
      testApp(
        const StaffHomePage(),
        overrides: [
          ...homeOverrides(
            official,
            answers: {
              ...homeAnswers,
              '/dashboard/barangay': {
                ...barangayDashboardAnswer,
                'status': {'status': 'normal', 'may_say_arriving': true},
              },
              '/selected-event': {
                'selected': _monitored,
                'chosen': false,
                'open_events': [_monitored],
                'closed_events': [],
              },
            },
          ),
          staffApiClientProvider.overrideWithValue(api),
          connectivityServiceProvider.overrideWithValue(
            ConnectivityService.forTesting(
              hasInterface: () async => true,
              probe: () async => true,
            ),
          ),
        ],
      ),
    );

    expect(find.text('Available when the event is Active'), findsOneWidget);
    // No DEMO mark on a practice event.
    expect(find.text('DEMO'), findsNothing);
    // Register and Give relief box wait, with the lock.
    final register = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Register family'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(register.onPressed, isNull);

    await tester.tap(find.text('Families are arriving'));
    await tester.pumpAndSettle();
    expect(find.text('Tell CSWD that families are arriving?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Purok 3 is walking in');
    await tester.tap(find.text('Tell CSWD'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('POST /evacuation-events/24/families-arriving'));
    expect(api.bodies.last, {'note': 'Purok 3 is walking in'});
  });

  testWidgets('Active: no lock, the buttons work', (tester) async {
    await _pumpTall(
      tester,
      testApp(const StaffHomePage(), overrides: homeOverrides(official)),
    );
    expect(find.text('Available when the event is Active'), findsNothing);
    expect(find.text('Families are arriving'), findsNothing);
  });

  test('the RegistrationOpen notification is recognised', () {
    expect(
      isRegistrationOpenNotification(
        const AppNotification(
          id: '1',
          title: 'Anything',
          message: '',
          read: false,
          type: 'RegistrationOpen',
        ),
      ),
      isTrue,
    );
    expect(
      isRegistrationOpenNotification(
        const AppNotification(
          id: '2',
          title: 'Registration is open: Typhoon Drill',
          message: '',
          read: false,
        ),
      ),
      isTrue,
    );
    expect(
      isRegistrationOpenNotification(
        const AppNotification(
          id: '3',
          title: 'Transfer request: 2 families',
          message: '',
          read: false,
        ),
      ),
      isFalse,
    );
  });
}
