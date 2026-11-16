import 'package:elikas_mobile/core/network/staff_api_client.dart';
import 'package:elikas_mobile/features/facility_requests/facility_requests.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';

void main() {
  test('the 19 checklist types', () {
    expect(facilityTypes.toSet(), hasLength(19));
  });

  test("a center's requests are read from the paginated list", () async {
    final api = FakeStaffApi()
      ..getBodies['GET /facility-requests'] = {
        'success': true,
        'data': {
          'data': [
            {
              'id': 7,
              'facility_type': 'toilet_female',
              'item': null,
              'quantity_needed': 4,
              'reason': 'One toilet for 80 women',
              'status': 'rejected',
              'review_note': 'Use the school toilets',
            },
          ],
          'meta': {'total': 1},
        },
      };
    final container = ProviderContainer(
      overrides: [staffApiClientProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    final list = await container.read(
      facilityRequestsForCenterProvider(71).future,
    );
    expect(list.single.status, 'rejected');
    expect(list.single.quantity, 4);
    expect(list.single.reviewNote, 'Use the school toilets');
    expect(api.bodies.single, {'evacuation_center_id': 71, 'per_page': 50});
  });
}
