import 'package:drift/native.dart';
import 'package:elikas_mobile/core/cache/staff_read_cache.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/database/staff_database.dart';
import 'package:elikas_mobile/features/monitoring/monitoring_page.dart';
import 'package:elikas_mobile/features/staff_shell/staff_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';
import '../../helpers/fake_staff_auth.dart';

void main() {
  test("each role gets its own tabs, Home first", () {
    List<int> branchesFor(session) => [
      for (final t in staffTabs)
        if (t.visibleTo(session)) t.branch,
    ];
    // CSWDO: Home (city monitoring), More.
    expect(branchesFor(cswd), [3, 1]);
    // Barangay official: Home, Centers, Relief, More.
    expect(branchesFor(official), [3, 0, 2, 1]);
  });

  test('a section is read with its event and DEMO flag', () async {
    final db = StaffDatabase.forExecutor(NativeDatabase.memory());
    addTearDown(db.close);
    final api = FakeStaffApi()
      ..getBodies['GET /monitoring/overview'] = {
        'success': true,
        'data': {
          'evacuation_event': {
            'id': 30,
            'name': 'DEMO - Typhoon Drill',
            'status': 'active',
            'is_demo': true,
          },
          'scope': {'barangay': null},
          'generated_at': '2026-11-16T02:00:00+00:00',
          'data': {
            'figures': {
              'persons': 120,
              'families': 40,
              'inside': 100,
              'outside': 20,
              'arrived_last_hour': 5,
              'centers_in_use': 3,
            },
            'attention': [
              {
                'kind': 'center_full',
                'level': 'danger',
                'text': 'LWCES (B) is 95% full (760 of 800).',
                'href': '/ec-board/71',
              },
            ],
          },
        },
      };
    final container = ProviderContainer(
      overrides: [
        staffReadCacheProvider.overrideWithValue(
          StaffReadCache(
            api,
            db,
            ConnectivityService.forTesting(
              hasInterface: () async => true,
              probe: () async => true,
              resultCacheTtl: Duration.zero,
            ),
            10,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final s = await container.read(
      monitoringSectionProvider('overview').future,
    );
    expect(s.isDemo, isTrue);
    expect(s.eventName, 'DEMO - Typhoon Drill');
    expect((s.data!['figures'] as Map)['persons'], 120);
  });
}
