// Screenshot tests live outside test/, so the analyzer does not know they are tests.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:convert';

import 'package:elikas_mobile/features/family_registration/domain/entities/lookup_entities.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/lookup_providers.dart';
import 'package:elikas_mobile/features/family_registration/presentation/register/register_family_page.dart';
import 'package:elikas_mobile/features/puroks/puroks.dart';
import 'package:elikas_mobile/features/staff_evacuation_centers/presentation/providers/own_centers_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/fake_staff_auth.dart';
import 'harness.dart';

final draft = {
  'evacuation_event_id': null,
  'barangay_id': 13,
  'displacement_type': 'inside_center',
  'evacuation_center_id': 71,
  'is_4ps_beneficiary': false,
  'purok_id': 7,
  'members': [
    {
      'first_name': 'Ana',
      'last_name': 'Reyes',
      'sex': 'female',
      'date_of_birth': '1985-03-04',
      'contact_number': '09171234567',
      'is_head_of_family': true,
      'is_pregnant': true,
    },
    {
      'first_name': 'Ben',
      'last_name': 'Reyes',
      'sex': 'male',
      'date_of_birth': '2015-06-01',
      'contact_number': '09171234567',
      'is_head_of_family': false,
    },
  ],
};

final overrides = [
  ...signedInAs(official),
  evacuationEventsLookupProvider.overrideWith(
    (ref) async => const [
      EvacuationEventLookup(id: 24, name: 'Typhoon Pepito', status: 'active'),
    ],
  ),
  ownCentersProvider.overrideWith(
    (ref) async => const [
      OwnCenter(
        center: EvacuationCenterLookup(
          id: 71,
          name: 'Binatagan Elementary School',
          barangayId: 13,
          status: 'active',
        ),
      ),
      OwnCenter(
        center: EvacuationCenterLookup(
          id: 72,
          name: 'Binatagan Covered Court',
          barangayId: 13,
          status: 'on_standby',
        ),
      ),
    ],
  ),
  puroksForBarangayProvider.overrideWith(
    (ref, id) async => const [
      Purok(id: 7, barangayId: 13, name: 'Purok 1'),
      Purok(id: 8, barangayId: 13, name: 'Purok 2'),
    ],
  ),
];

void main() {
  setUpAll(loadFonts);

  for (final scale in [1.0, 1.3]) {
    for (var step = 0; step < 4; step++) {
      testWidgets('register step ${step + 1} at $scale', (tester) async {
        SharedPreferences.setMockInitialValues({
          'elikas.registerDraft.4': jsonEncode(draft),
        });
        await shoot(
          tester,
          const RegisterFamilyPage(),
          'register_step${step + 1}${scale == 1.0 ? '' : '_scale13'}',
          overrides: overrides,
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
