import 'package:elikas_mobile/core/widgets/occupancy_progress.dart';
import 'package:elikas_mobile/features/evacuation_centers/domain/entities/evacuation_center.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/lookup_entities.dart';
import 'package:elikas_mobile/features/staff_evacuation_centers/presentation/providers/own_centers_provider.dart';
import 'package:elikas_mobile/features/staff_evacuation_centers/presentation/widgets/center_needs_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_auth.dart';

OwnCenter _center({
  String? source = 'official',
  double? lat = 13.2,
  String approval = 'approved',
}) => OwnCenter(
  center: EvacuationCenterLookup(
    id: 12,
    name: 'Binatagan Hall',
    barangayId: 13,
    status: 'active',
    approvalStatus: approval,
  ),
  public: approval != 'approved'
      ? null
      : EvacuationCenter(
          id: 12,
          name: 'Binatagan Hall',
          type: 'barangay_hall',
          latitude: lat,
          longitude: lat == null ? null : 123.5,
          capacityPersons: 112,
          capacitySource: source,
          status: 'active',
        ),
);

void main() {
  test(
    'needs details: capacity unknown or estimated, no location, no checklist',
    () {
      expect(centerNeeds(_center(), null), isEmpty);
      expect(centerNeeds(_center(source: 'estimated'), null), {
        CenterNeed.capacityEstimated,
      });
      expect(centerNeeds(_center(source: 'unknown', lat: null), null), {
        CenterNeed.capacityMissing,
        CenterNeed.location,
      });
      // The dashboard row: readiness (apps-api-2026-11-24.md 7.1).
      expect(centerNeeds(_center(), {'readiness': 'no_checklist'}), {
        CenterNeed.checklist,
      });
      expect(centerNeeds(_center(), {'readiness': 'below'}), {
        CenterNeed.supplies,
      });
      expect(centerNeeds(_center(), {'readiness': 'ready'}), isEmpty);
      expect(centerNeeds(_center(), {'readiness': null}), isEmpty);
      // A pending center has no public copy: the dashboard row tells.
      expect(
        centerNeeds(_center(approval: 'pending'), {
          'readiness': 'no_capacity',
          'has_location': false,
          'capacity_persons': null,
        }),
        {CenterNeed.capacityMissing, CenterNeed.location},
      );
    },
  );

  testWidgets('the occupancy line says est. for an estimate, with separators', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        const Scaffold(
          body: Column(
            children: [
              OccupancyProgress(
                current: 1050,
                capacity: 1200,
                percent: 87.5,
                color: Colors.amber,
                estimated: true,
              ),
              CenterFillBar(
                occupancy: 108,
                capacity: 112,
                status: 'nearly_full',
              ),
              CenterFillBar(occupancy: 3, capacity: null, status: 'active'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1,050 / 1,200 est. (88%)'), findsOneWidget);
    // One bar: an unknown capacity has none.
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
  });
}
