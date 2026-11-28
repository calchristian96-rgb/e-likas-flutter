import 'package:drift/native.dart';
import 'package:elikas_mobile/core/cache/staff_read_cache.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/database/staff_database.dart';
import 'package:elikas_mobile/features/facility_requests/facility_requests.dart';
import 'package:elikas_mobile/features/facility_requests/facility_requests_page.dart';
import 'package:elikas_mobile/features/outbox/data/outbox_repository.dart';
import 'package:elikas_mobile/features/outbox/domain/pending_action.dart';
import 'package:elikas_mobile/features/outbox/presentation/outbox_providers.dart';
import 'package:elikas_mobile/features/staff_evacuation_centers/presentation/providers/own_centers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';
import '../../helpers/fake_staff_auth.dart';
import '../../helpers/home_fixtures.dart';

class _NoSync extends StaffSyncAll {
  _NoSync(super.ref);

  @override
  Future<OutboxRunResult> call({bool automatic = true}) async =>
      const OutboxRunResult();
}

final _requests = {
  'data': [
    {
      'id': 7,
      'evacuation_center': {'id': 12, 'name': 'Binatagan Hall'},
      'facility_type': 'toilet_female',
      'quantity_needed': 10,
      'quantity_approved': 6,
      'unit': 'pieces',
      'status': 'sent',
      'may_receive': true,
    },
    {
      'id': 8,
      'evacuation_center': {'id': 12, 'name': 'Binatagan Hall'},
      'item': 'Water containers',
      'quantity_needed': 20,
      'status': 'received',
    },
  ],
};

final _suggestions = {
  'suggestions': [
    // apps-api-2026-11-24.md 7.2.
    {
      'center': {'id': 12, 'name': 'Binatagan Hall'},
      'facility_type': 'handwashing_facility',
      'label': 'handwashing stations',
      'quantity': 3,
      'unit': 'stations',
      'reason': 'Standards for a full center: 3 more',
    },
  ],
};

void main() {
  test('Approved 6 of 10, the unit, and the received statuses', () {
    final r = FacilityRequest.fromJson(
      (_requests['data'] as List).first as Map<String, dynamic>,
    );
    expect(r.unit, 'pieces');
    expect(r.quantityApproved, 6);
    expect(r.mayReceive, isTrue);
    expect(r.centerId, 12);
    final s = FacilitySuggestion.fromJson(
      (_suggestions['suggestions'] as List).first as Map<String, dynamic>,
    )!;
    expect(s.centerId, 12);
    expect(s.label, 'handwashing stations');
    expect(s.asPrefill.quantity, 3);
    expect(s.body, {
      'facility_type': 'handwashing_facility',
      'quantity_needed': 3,
      'unit': 'stations',
      'reason': 'Standards for a full center: 3 more',
    });
  });

  testWidgets('suggested for your centers, Mark received, Request again', (
    tester,
  ) async {
    final db = StaffDatabase.forExecutor(NativeDatabase.memory());
    addTearDown(db.close);
    final offline = ConnectivityService.forTesting(
      hasInterface: () async => false,
      probe: () async => false,
      resultCacheTtl: Duration.zero,
    );
    final outbox = OutboxRepository(db, FakeStaffApi(), offline, 4);
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(720, 5000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      testApp(
        const FacilityRequestsPage(),
        overrides: [
          ...signedInAs(official),
          staffReadCacheProvider.overrideWithValue(
            FakeReadCache({
              '/facility-requests': _requests,
              '/facility-requests/suggestions': _suggestions,
            }),
          ),
          outboxRepositoryProvider.overrideWithValue(outbox),
          pendingActionsProvider.overrideWith((ref) {
            ref.watch(outboxRevisionProvider);
            return outbox.getAll();
          }),
          staffSyncAllProvider.overrideWith(_NoSync.new),
          connectivityServiceProvider.overrideWithValue(offline),
          ownCentersProvider.overrideWith((ref) async => const []),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SUGGESTED FOR YOUR CENTERS'), findsOneWidget);
    expect(find.text('Approved 6 of 10'), findsOneWidget);
    expect(find.text('Received'), findsOneWidget);
    expect(find.text('Request again'), findsOneWidget);

    await tester.tap(find.text('Mark received'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Mark received'),
      ),
    );
    await tester.pumpAndSettle();
    final queued = (await outbox.getAll()).single;
    expect(queued.kind, PendingActionKind.facilityReceive);
    expect(queued.path, '/facility-requests/7/receive');

    await tester.pumpWidget(const SizedBox());
    offline.dispose();
    await tester.pump(const Duration(seconds: 10));
  });
}
