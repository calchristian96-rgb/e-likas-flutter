import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/network/staff_api_client.dart';
import 'package:elikas_mobile/features/barangay_status/staff/barangay_page.dart';
import 'package:elikas_mobile/features/staff_home/cswd_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';
import '../../helpers/fake_staff_auth.dart';
import '../../helpers/home_fixtures.dart';

void main() {
  test('an evacuation order: who ordered it, when, the summary', () {
    final s = OwnSituation.fromJson({
      'evacuation_event': {'id': 80, 'name': 'Typhoon Rolly'},
      'open': true,
      'statuses': const [],
      'barangays': [
        {
          'barangay': {'id': 13, 'name': 'Binatagan'},
          'status': 'forced_evacuation',
          'label': 'Forced evacuation',
          'may_update': false,
          'order': {
            'ordered_by': 'city_mayor',
            'ordered_by_label': 'the City Mayor',
            'ordered_at': '2026-11-17T07:00:00+00:00',
            'summary':
                'Forced evacuation ordered by the City Mayor at 3:00 PM, '
                'recorded by Ana Cruz',
          },
        },
      ],
    }, 13)!;
    expect(s.order?.orderedByLabel, 'the City Mayor');
    expect(s.order?.summary, contains('recorded by Ana Cruz'));
    expect(EvacuationOrder.fromJson(null), isNull);
  });

  testWidgets('CSWDO records an order with who ordered it, online only', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(720, 3000);
    addTearDown(tester.view.reset);
    final api = FakeStaffApi()
      ..answer('POST /gis/barangay-status', (
        201,
        {
          'success': true,
          'message': 'Forced evacuation order recorded for Binatagan.',
          'data': <String, dynamic>{},
        },
      ));
    await tester.pumpWidget(
      testApp(
        const CswdBarangayDetailPage(barangayId: 13),
        overrides: [
          ...homeOverrides(cswd),
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

    await tester.tap(find.widgetWithText(OutlinedButton, 'Forced evacuation'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Record a forced evacuation order for Binatagan in Typhoon Pepito?',
      ),
      findsOneWidget,
    );
    final record = find.widgetWithText(FilledButton, 'Record order');
    // Nothing chosen yet: who ordered it is required.
    expect(tester.widget<FilledButton>(record).onPressed, isNull);

    await tester.tap(find.text('The City Mayor'));
    await tester.pumpAndSettle();
    await tester.tap(record);
    await tester.pumpAndSettle();

    expect(api.calls, contains('POST /gis/barangay-status'));
    final body = api.bodies.last as Map<String, dynamic>;
    expect(body['status'], 'forced_evacuation');
    expect(body['ordered_by'], 'city_mayor');
    expect(body.containsKey('ordered_by_other'), isFalse);
    expect(
      find.text('Forced evacuation order recorded for Binatagan.'),
      findsOneWidget,
    );
  });
}
