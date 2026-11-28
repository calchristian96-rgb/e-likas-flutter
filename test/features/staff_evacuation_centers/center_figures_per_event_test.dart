import 'package:drift/native.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/database/staff_database.dart';
import 'package:elikas_mobile/core/error/result.dart';
import 'package:elikas_mobile/features/box_relief/relief_page.dart';
import 'package:elikas_mobile/features/ec_board/presentation/pages/ec_board_centers_list_page.dart';
import 'package:elikas_mobile/features/evacuation_centers/data/models/evacuation_center_model.dart';
import 'package:elikas_mobile/features/evacuation_centers/domain/entities/evacuation_center.dart';
import 'package:elikas_mobile/features/evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import 'package:elikas_mobile/features/family_registration/data/datasources/lookup_local_datasource.dart';
import 'package:elikas_mobile/features/family_registration/data/datasources/lookup_remote_datasource.dart';
import 'package:elikas_mobile/features/family_registration/data/repositories/lookup_repository_impl.dart';
import 'package:elikas_mobile/features/family_registration/data/services/lookup_sync_timestamps.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/lookup_entities.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/lookup_providers.dart';
import 'package:elikas_mobile/features/staff_evacuation_centers/presentation/pages/staff_evacuation_centers_list_page.dart';
import 'package:elikas_mobile/features/staff_shell/current_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_staff_api.dart';
import '../../helpers/fake_staff_auth.dart';

/// The plain staff list row of LWCES (B) (backend d17f6de, doc 3):
/// Typhoon Drill (#48) has 87 people there, Incoming Typhoon (#49) none.
Map<String, dynamic> _lwces({required int event}) => {
  'id': 7,
  'name': 'LWCES (B)',
  'barangay_id': 13,
  'status': 'active',
  'effective_status': event == 48 ? 'active' : 'on_standby',
  'approval_status': 'approved',
  'has_pending_change': false,
  'capacity_persons': 1088,
  'current_occupancy': event == 48 ? 87 : 0,
  'occupancy_percent': event == 48 ? 8.0 : 0.0,
  'total_occupancy': 87,
  'other_events': event == 48
      ? []
      : [
          {
            'event_id': 48,
            'name': 'Typhoon Drill',
            'status': 'active',
            'persons': 87,
            'families': 21,
          },
        ],
  'occupancy_note': event == 48 ? null : '87 people here for Typhoon Drill',
};

EvacuationCenterLookup _lookup({required int event}) {
  final j = _lwces(event: event);
  return EvacuationCenterLookup(
    id: 7,
    name: 'LWCES (B)',
    barangayId: 13,
    status: j['effective_status'] as String,
    capacityPersons: 1088,
    currentOccupancy: j['current_occupancy'] as int,
    occupancyPercent: j['occupancy_percent'] as double,
    totalOccupancy: 87,
    occupancyNote: j['occupancy_note'] as String?,
  );
}

/// The public copy has no event: it counts every open event (87).
const _publicLwces = EvacuationCenter(
  id: 7,
  name: 'LWCES (B)',
  type: 'school',
  latitude: 13.2,
  longitude: 123.5,
  capacityPersons: 1088,
  currentOccupancy: 87,
  occupancyPercent: 8,
  capacitySource: 'official',
  status: 'active',
);

void main() {
  group('the staff list carries the figures of the selected event', () {
    test('sends evacuation_event_id and reads the new fields', () async {
      final api = FakeStaffApi()
        ..getBodies['GET /evacuation-centers'] = {
          'success': true,
          'data': [_lwces(event: 49)],
        };
      final rows = await LookupRemoteDataSource(
        api,
      ).getEvacuationCenters(eventId: 49);
      expect(api.bodies.single, {
        'include_rejected': 1,
        'evacuation_event_id': 49,
      });
      final row = rows.single;
      expect(row.status, 'on_standby');
      expect(row.capacityPersons, 1088);
      expect(row.currentOccupancy, 0);
      expect(row.occupancyPercent, 0.0);
      expect(row.totalOccupancy, 87);
      expect(row.occupancyNote, '87 people here for Typhoon Drill');
      expect(row.figuresEventId, 49);
    });

    test(
      'offline, saved figures show only under the event they were read for',
      () async {
        SharedPreferences.setMockInitialValues({});
        final db = StaffDatabase.forExecutor(NativeDatabase.memory());
        addTearDown(db.close);
        var online = true;
        final api = FakeStaffApi()
          ..getBodies['GET /evacuation-centers'] = {
            'success': true,
            'data': [_lwces(event: 48)],
          };
        final repo = LookupRepositoryImpl(
          remote: LookupRemoteDataSource(api),
          local: LookupLocalDataSource(db),
          connectivity: ConnectivityService.forTesting(
            hasInterface: () async => online,
            probe: () async => online,
            resultCacheTtl: Duration.zero,
          ),
          syncTimestamps: LookupSyncTimestampService(),
        );
        final live = await repo.getEvacuationCenters(eventId: 48);
        expect((live as Success).value.single.currentOccupancy, 87);

        online = false;
        final same = await repo.getEvacuationCenters(eventId: 48);
        final sameRow =
            (same as Success<List<EvacuationCenterLookup>>).value.single;
        expect(sameRow.currentOccupancy, 87);
        expect(sameRow.capacityPersons, 1088);

        // Saved under #48, asked for #49: never #48's people.
        final other = await repo.getEvacuationCenters(eventId: 49);
        final otherRow =
            (other as Success<List<EvacuationCenterLookup>>).value.single;
        expect(otherRow.currentOccupancy, isNull);
        expect(otherRow.occupancyNote, isNull);
        expect(otherRow.capacityPersons, 1088);
      },
    );

    test('the lookup list is read again for the selected event', () async {
      final asked = <int?>[];
      final container = ProviderContainer(
        overrides: [
          currentStaffEventProvider.overrideWith(
            (ref) async => const EvacuationEventLookup(
              id: 49,
              name: 'Incoming Typhoon',
              status: 'monitoring',
            ),
          ),
          lookupRepositoryProvider.overrideWithValue(
            _RecordingLookupRepo(asked),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(evacuationCentersLookupProvider.future);
      expect(asked, [49]);
    });
  });

  test('the center detail shows the effective status and the note', () {
    final model = EvacuationCenterModel.fromStaffJson({
      ..._lwces(event: 49),
      'type': 'school',
      'barangay': {'id': 13, 'name': 'Binatagan'},
    });
    expect(model.status, 'on_standby');
    expect(model.toEntity().occupancyNote, '87 people here for Typhoon Drill');
    expect(model.toEntity().totalOccupancy, 87);
    // Older servers: the stored status.
    final old = EvacuationCenterModel.fromStaffJson({
      'id': 7,
      'name': 'LWCES (B)',
      'type': 'school',
      'status': 'active',
    });
    expect(old.status, 'active');
  });

  List<Override> listOverrides(int event) => [
    ...signedInAs(official),
    evacuationCentersLookupProvider.overrideWith(
      (ref) async => [_lookup(event: event)],
    ),
    allEvacuationCentersProvider.overrideWith((ref) async => [_publicLwces]),
    barangayBoxesProvider.overrideWith((ref) async => null),
  ];

  testWidgets(
    'EC Board under Incoming Typhoon: 0 / 1,088, On standby, the note, '
    'Evacuees 0 (not the public 87)',
    (tester) async {
      await tester.pumpWidget(
        testApp(const EcBoardCentersListPage(), overrides: listOverrides(49)),
      );
      await tester.pumpAndSettle();
      expect(find.text('0 / 1,088'), findsOneWidget);
      expect(find.text('ON STANDBY'), findsOneWidget);
      expect(find.text('87 people here for Typhoon Drill'), findsOneWidget);
      expect(find.text('87 / 1,088'), findsNothing);
      // The Evacuees total of the strip is the event's own: 0.
      expect(find.text('EVACUEES'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    },
  );

  testWidgets('EC Board under Typhoon Drill: 87, Active, no note', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(const EcBoardCentersListPage(), overrides: listOverrides(48)),
    );
    await tester.pumpAndSettle();
    expect(find.text('87 / 1,088'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.textContaining('people here for'), findsNothing);
    expect(find.text('87'), findsOneWidget);
  });

  testWidgets('Centers list under Incoming Typhoon: 0, On standby, the note', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        const StaffEvacuationCentersListPage(),
        overrides: listOverrides(49),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('0 / 1,088 (0%)'), findsOneWidget);
    expect(find.text('ON STANDBY'), findsOneWidget);
    expect(find.text('87 people here for Typhoon Drill'), findsOneWidget);
    expect(find.textContaining('87 / 1,088'), findsNothing);
  });
}

class _RecordingLookupRepo extends LookupRepositoryImpl {
  _RecordingLookupRepo(this.asked)
    : super(
        remote: LookupRemoteDataSource(FakeStaffApi()),
        local: LookupLocalDataSource(
          StaffDatabase.forExecutor(NativeDatabase.memory()),
        ),
        connectivity: ConnectivityService.forTesting(
          hasInterface: () async => false,
          probe: () async => false,
          resultCacheTtl: Duration.zero,
        ),
        syncTimestamps: LookupSyncTimestampService(),
      );

  final List<int?> asked;

  @override
  Future<Result<List<EvacuationCenterLookup>>> getEvacuationCenters({
    int? eventId,
  }) async {
    asked.add(eventId);
    return const Success([]);
  }
}
