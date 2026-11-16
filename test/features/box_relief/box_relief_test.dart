import 'package:drift/native.dart';
import 'package:elikas_mobile/core/cache/staff_read_cache.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/database/staff_database.dart';
import 'package:elikas_mobile/features/box_relief/box_relief_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';

/// The barangay page example from backend docs/box-relief-api-step11.md.
const barangayPage = {
  'evacuation_event': {'id': 24, 'name': 'Typhoon', 'status': 'active'},
  'barangay': {'id': 1, 'name': 'Abella'},
  'has_official_account': true,
  'can_act': true,
  'acting_on_behalf': false,
  'can_request_shortfall': true,
  'need': 7,
  'count_validated': true,
  'rounds': [
    {
      'id': 1,
      'round_number': 1,
      'opened_at': '2026-11-12T00:00:00Z',
      'need': 7,
      'dispatched': 7,
      'in_transit': 0,
      'received': 6,
      'given': 1,
      'left_to_give': 5,
      'short': 1,
      'can_dispatch': 1,
      'requested': 0,
      'can_request': 1,
      'dispatches': [
        {
          'id': 1,
          'quantity': 7,
          'confirmed_quantity': 6,
          'voided': false,
          'dispatched_at': '2026-11-12T01:00:00Z',
        },
        {
          'id': 2,
          'quantity': 3,
          'confirmed_quantity': null,
          'voided': false,
          'dispatched_at': '2026-11-13T01:00:00Z',
        },
        {'id': 3, 'quantity': 2, 'confirmed_quantity': null, 'voided': true},
      ],
      'shortfall_requests': [
        {'id': 1, 'quantity': 1, 'status': 'pending'},
      ],
    },
  ],
};

void main() {
  test(
    'the barangay page: figures, dispatches to confirm, shortfall requests',
    () {
      final boxes = BarangayBoxes.fromJson(barangayPage);
      final round = boxes.latestRound!;
      expect(round.figures.received, 6);
      expect(round.figures.short, 1);
      expect(round.figures.canRequest, 1);
      expect(
        round.dispatches
            .where((d) => d.waitingForConfirmation)
            .map((d) => d.id),
        [2],
      );
      expect(round.shortfallRequests.single.status, 'pending');
      expect(boxes.canAct, isTrue);
    },
  );

  test('a staff read is saved and shown offline with its age', () async {
    final db = StaffDatabase.forExecutor(NativeDatabase.memory());
    addTearDown(db.close);
    final api = FakeStaffApi()
      ..getBodies['GET /box-relief/barangay'] = {
        'success': true,
        'data': barangayPage,
      };
    var online = true;
    final cache = StaffReadCache(
      api,
      db,
      ConnectivityService.forTesting(
        hasInterface: () async => online,
        probe: () async => online,
        resultCacheTtl: Duration.zero,
      ),
      4,
    );
    final live = await cache.get(
      '/box-relief/barangay',
      query: {'evacuation_event_id': 24},
    );
    expect(live.isFromCache, isFalse);
    online = false;
    final saved = await cache.get(
      '/box-relief/barangay',
      query: {'evacuation_event_id': 24},
    );
    expect(saved.isFromCache, isTrue);
    expect(saved.data['need'], 7);
    expect(
      () =>
          cache.get('/box-relief/barangay', query: {'evacuation_event_id': 25}),
      throwsStateError,
    );
  });
}
