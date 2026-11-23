import 'package:elikas_mobile/features/staff_home/official_plan.dart';
import 'package:elikas_mobile/features/staff_home/staff_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_auth.dart';
import '../../helpers/home_fixtures.dart';

Future<void> _pumpTall(WidgetTester tester, Widget app) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(720, 5000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the plan: forecast, list, space, centers ready; the To do', (
    tester,
  ) async {
    await _pumpTall(
      tester,
      testApp(const StaffHomePage(), overrides: homeOverrides(official)),
    );
    expect(find.text('Plan for'), findsOneWidget);
    expect(find.text('1,250 families'), findsOneWidget);
    expect(
      find.textContaining('Forecast 40 to 1,250 families'),
      findsOneWidget,
    );
    expect(find.text('Your list'), findsOneWidget);
    expect(find.text('12 families'), findsOneWidget);
    expect(find.text('5 of 12 checked in'), findsOneWidget);
    expect(find.text('Center space vs forecast'), findsOneWidget);
    expect(find.text('3,800 spaces for 4,300 persons'), findsOneWidget);
    expect(find.text('Short of 500 spaces'), findsOneWidget);
    expect(find.text('Centers ready'), findsOneWidget);
    expect(find.text('2 of 4'), findsOneWidget);
    // The server's To do, as it comes, with its action.
    expect(
      find.text('3 of your 4 centers have no capacity or only an estimate'),
      findsOneWidget,
    );
    expect(find.text('Request supplies'), findsOneWidget);
    expect(find.text('Change status'), findsOneWidget);
  });

  test('To do kinds map to app screens; unknown kinds get no button', () {
    expect(todoTargetOf({'kind': 'center_location'}), TodoTarget.centers);
    expect(todoTargetOf({'kind': 'facilities_checklist'}), TodoTarget.centers);
    expect(todoTargetOf({'kind': 'supplies_short'}), TodoTarget.supplies);
    expect(todoTargetOf({'kind': 'something_new'}), TodoTarget.none);
  });
}
