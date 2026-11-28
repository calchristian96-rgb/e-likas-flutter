import 'package:elikas_mobile/core/widgets/staff_mode_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_staff_auth.dart';

/// Signed-in staff on the resident app see a clear amber banner back to
/// Staff Mode; residents see nothing.
void main() {
  testWidgets('signed in: amber banner with the name and Staff Mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        const Scaffold(body: StaffModeBanner()),
        overrides: signedInAs(official),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Signed in as staff: Ana Official'), findsOneWidget);
    expect(find.text('STAFF MODE'), findsOneWidget);
    final material = tester.widget<Material>(
      find
          .ancestor(
            of: find.text('STAFF MODE'),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, staffModeAmber);
  });

  testWidgets('a resident: no banner', (tester) async {
    await tester.pumpWidget(
      testApp(
        const Scaffold(body: StaffModeBanner()),
        overrides: signedInAs(null),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Signed in as staff'), findsNothing);
  });
}
