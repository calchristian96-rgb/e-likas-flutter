import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/network/staff_api_client.dart';
import 'package:elikas_mobile/features/staff_auth/domain/entities/staff_session.dart';
import 'package:elikas_mobile/features/staff_home/cswd_actions.dart';
import 'package:elikas_mobile/features/staff_home/staff_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';
import '../../helpers/fake_staff_auth.dart';
import '../../helpers/home_fixtures.dart';

final _cswdManager = StaffSession(
  id: cswd.id,
  name: cswd.name,
  email: cswd.email,
  role: cswd.role,
  roleDisplayName: cswd.roleDisplayName,
  permissions: {...cswd.permissions, 'events.manage'},
);

const _monitored = {
  'id': 24,
  'name': 'Incoming Typhoon',
  'status': 'monitoring',
  'is_demo': true,
};

void main() {
  test('progress: registered against the list, behind first', () {
    final p = BarangayProgress.fromJson({
      'barangay': {'id': 13, 'name': 'Binatagan'},
      'families': 6,
      'persons': 22,
      'list': {'families': 12, 'persons': 47, 'checked_in': 5},
    })!;
    expect(p.expectedFamilies, 12);
    expect(p.share, 0.5);
    expect(p.listCheckedIn, 5);
    final none = BarangayProgress.fromJson({
      'barangay': {'id': 14, 'name': 'Bay'},
      'families': 3,
      'list': null,
    })!;
    expect(none.expectedFamilies, isNull);
    expect(none.share, isNull);
  });

  testWidgets('Start evacuation: confirm, online, then the event is Active', (
    tester,
  ) async {
    final api = FakeStaffApi();
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(720, 4000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      testApp(
        const StaffHomePage(),
        overrides: [
          ...homeOverrides(
            _cswdManager,
            answers: {
              ...homeAnswers,
              '/selected-event': {
                'selected': _monitored,
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
    await tester.pumpAndSettle();
    expect(find.text('Evacuation progress'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Start evacuation'));
    await tester.pumpAndSettle();
    expect(
      find.text('Start the evacuation for Incoming Typhoon?'),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Start evacuation'),
      ),
    );
    await tester.pumpAndSettle();
    expect(api.calls, contains('POST /evacuation-events/24/start'));
  });

  testWidgets('no events.manage: no Start evacuation', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(720, 4000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      testApp(
        const StaffHomePage(),
        overrides: [
          ...homeOverrides(
            cswd,
            answers: {
              ...homeAnswers,
              '/selected-event': {
                'selected': _monitored,
                'open_events': [_monitored],
                'closed_events': [],
              },
            },
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Start evacuation'), findsNothing);
  });
}
