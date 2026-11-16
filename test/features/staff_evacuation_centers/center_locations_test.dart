import 'package:elikas_mobile/core/network/staff_api_client.dart';
import 'package:elikas_mobile/features/staff_evacuation_centers/presentation/widgets/center_location_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';

void main() {
  test(
    'center-locations: no location yet, and a location waiting for CSWD',
    () async {
      final api = FakeStaffApi()
        ..getBodies['GET /gis/center-locations'] = {
          'success': true,
          'data': {
            'summary': {
              'centers': 2,
              'with_location': 0,
              'without_location': 2,
              'pending_location': 1,
            },
            'without_location': [
              {
                'id': 71,
                'name': 'LWCES (B)',
                'has_location': false,
                'pending_location': null,
                'location_source': null,
              },
            ],
            'pending': [
              {
                'id': 72,
                'name': 'Chapel',
                'has_location': false,
                'location_source': null,
                'pending_location': {
                  'latitude': 13.1,
                  'longitude': 123.4,
                  'change_request_id': 9,
                  'submitted_at': '2026-11-16T02:00:00+00:00',
                },
              },
            ],
          },
        };
      final container = ProviderContainer(
        overrides: [staffApiClientProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      final states = await container.read(centerLocationsProvider.future);
      expect(states[71]!.isPending, isFalse);
      expect(states[71]!.hasLocation, isFalse);
      expect(states[72]!.isPending, isTrue);
    },
  );
}
