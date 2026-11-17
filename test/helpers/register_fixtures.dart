import 'package:elikas_mobile/features/family_registration/domain/entities/lookup_entities.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/lookup_providers.dart';
import 'package:elikas_mobile/features/puroks/puroks.dart';
import 'package:elikas_mobile/features/staff_evacuation_centers/presentation/providers/own_centers_provider.dart';

import 'fake_staff_auth.dart';

/// A saved Register family draft (Ana Reyes, pregnant, and Ben) for the
/// official of Binatagan, and that barangay's event, centers and puroks.
final registerDraft = {
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

final registerOverrides = [
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
