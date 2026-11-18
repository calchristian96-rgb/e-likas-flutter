// Screenshot tests live outside test/, so the analyzer does not know they are tests.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:convert';

import 'package:elikas_mobile/features/family_registration/presentation/register/register_family_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/register_fixtures.dart';
import 'harness.dart';

void main() {
  setUpAll(loadFonts);

  // Step 3 with a private house (Part 1).
  testWidgets('register step 3, private house', (tester) async {
    SharedPreferences.setMockInitialValues({
      'elikas.registerDraft.4': jsonEncode({
        ...registerDraft,
        'displacement_type': 'outside_center',
        'host_name': 'Carmen Reyes',
        'host_address': 'Zone 3, near the chapel',
        'host_purok_id': 8,
      }),
    });
    await shoot(
      tester,
      const RegisterFamilyPage(),
      'register_step3_private',
      overrides: registerOverrides,
      before: (tester) async {
        for (var i = 0; i < 2; i++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }
      },
    );
  });

  for (final scale in [1.0, 1.3]) {
    for (var step = 0; step < 4; step++) {
      testWidgets('register step ${step + 1} at $scale', (tester) async {
        SharedPreferences.setMockInitialValues({
          'elikas.registerDraft.4': jsonEncode(registerDraft),
        });
        await shoot(
          tester,
          const RegisterFamilyPage(),
          'register_step${step + 1}${scale == 1.0 ? '' : '_scale13'}',
          overrides: registerOverrides,
          textScale: scale,
          before: (tester) async {
            for (var i = 0; i < step; i++) {
              await tester.tap(find.text('Next'));
              await tester.pumpAndSettle();
            }
          },
        );
      });
    }
  }
}
