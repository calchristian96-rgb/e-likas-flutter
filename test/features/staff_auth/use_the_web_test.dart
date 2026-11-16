import 'package:elikas_mobile/features/staff_auth/presentation/widgets/staff_auth_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_auth.dart';

void main() {
  Widget guarded() =>
      StaffAuthGuard(builder: (context, session) => const Text('staff screen'));

  testWidgets('the administrator is sent to the web', (tester) async {
    await tester.pumpWidget(
      testApp(guarded(), overrides: signedInAs(administrator)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Use the web'), findsOneWidget);
    expect(find.text('staff screen'), findsNothing);
  });

  testWidgets('an official reaches the staff screen', (tester) async {
    await tester.pumpWidget(
      testApp(guarded(), overrides: signedInAs(official)),
    );
    await tester.pumpAndSettle();
    expect(find.text('staff screen'), findsOneWidget);
  });
}
