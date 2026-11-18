import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/network/staff_api_client.dart';
import 'package:elikas_mobile/features/staff_home/cswd_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';
import '../../helpers/fake_staff_auth.dart';
import '../../helpers/home_fixtures.dart';

/// CSWDO "Submit for this barangay" (POST /barangays/{id}/count-submissions):
/// the registered count, a confirm dialog, online only; only for a
/// barangay with no official account.
Future<FakeStaffApi> _pump(
  WidgetTester tester, {
  bool online = true,
  Map<String, Map<String, dynamic>>? answers,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(720, 3200);
  addTearDown(tester.view.reset);
  final api = FakeStaffApi()
    ..answer('POST /barangays/13/count-submissions', (
      201,
      {
        'success': true,
        'message': 'Final count sent to CSWD for validation.',
        'data': <String, dynamic>{},
      },
    ));
  final connectivity = online
      ? ConnectivityService.forTesting(
          hasInterface: () async => true,
          probe: () async => true,
        )
      : _Offline();
  await tester.pumpWidget(
    testApp(
      const CswdBarangayDetailPage(barangayId: 13),
      overrides: [
        ...homeOverrides(cswd, answers: answers),
        staffApiClientProvider.overrideWithValue(api),
        connectivityServiceProvider.overrideWithValue(connectivity),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return api;
}

/// No connection, and no retry timer left running after the test.
class _Offline implements ConnectivityService {
  @override
  Future<bool> get hasConnection async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('the registered count, confirmed, then sent', (tester) async {
    final api = await _pump(tester);
    expect(
      find.text('Registered now: 42 families, 150 persons'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Submit for this barangay'));
    await tester.tap(find.text('Submit for this barangay'));
    await tester.pumpAndSettle();
    expect(find.text('Submit the final count for Binatagan?'), findsOneWidget);
    expect(find.text('Check: 1 possible duplicate.'), findsOneWidget);
    expect(
      find.textContaining('Submitted by CSWD for the barangay'),
      findsOneWidget,
    );
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('POST /barangays/13/count-submissions'));
    expect(api.bodies.last, {'evacuation_event_id': 24});
    expect(
      find.text('Final count sent to CSWD for validation.'),
      findsOneWidget,
    );
  });

  testWidgets('offline: nothing is sent or saved for later', (tester) async {
    final api = await _pump(tester, online: false);
    await tester.ensureVisible(find.text('Submit for this barangay'));
    await tester.tap(find.text('Submit for this barangay'));
    await tester.pumpAndSettle();
    expect(find.text('Submit the final count for Binatagan?'), findsNothing);
    expect(
      find.text('Submitting for a barangay needs a connection.'),
      findsOneWidget,
    );
    expect(api.calls, isNot(contains('POST /barangays/13/count-submissions')));
  });

  testWidgets('a barangay with its own official: no button', (tester) async {
    final answers = {...homeAnswers};
    answers['/count-submissions/computed'] = {
      ...answers['/count-submissions/computed']!,
      'has_official_account': true,
    };
    await _pump(tester, answers: answers);
    expect(find.text('Submit for this barangay'), findsNothing);
    expect(
      find.text("Binatagan's official submits the count."),
      findsOneWidget,
    );
  });
}
