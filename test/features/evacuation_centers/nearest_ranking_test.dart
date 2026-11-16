import 'package:drift/native.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/database/resident_database.dart';
import 'package:elikas_mobile/core/error/result.dart';
import 'package:elikas_mobile/core/sync/sync_timestamps.dart';
import 'package:elikas_mobile/features/evacuation_centers/data/datasources/evacuation_centers_local_datasource.dart';
import 'package:elikas_mobile/features/evacuation_centers/data/datasources/evacuation_centers_remote_datasource.dart';
import 'package:elikas_mobile/features/evacuation_centers/data/repositories/evacuation_centers_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_api_client.dart';

Map<String, dynamic> _c(int id, double? lat, String status) => {
  'id': id,
  'name': 'Center $id',
  'type': 'school',
  'address': null,
  'barangay_id': 13,
  'barangay': 'Binatagan',
  'latitude': lat,
  'longitude': lat == null ? null : 123.5,
  'capacity_persons': 100,
  'current_occupancy': id,
  'occupancy_percent': id.toDouble(),
  'status': status,
};

void main() {
  test(
    'nearest is ranked from the full list: occupancy kept, closed and unplaced left out',
    () async {
      SharedPreferences.setMockInitialValues({});
      final db = ResidentDatabase.forExecutor(NativeDatabase.memory());
      addTearDown(db.close);
      final api = FakeApiClient({
        'public/evacuation-centers': {
          'success': true,
          'data': [
            _c(1, 13.30, 'active'),
            _c(2, 13.21, 'on_standby'),
            _c(3, 13.20, 'closed'),
            _c(4, null, 'active'),
          ],
        },
      });
      final repo = EvacuationCentersRepositoryImpl(
        remoteDatasource: EvacuationCentersRemoteDatasource(api),
        localDatasource: EvacuationCentersLocalDatasource(db),
        connectivityService: ConnectivityService.forTesting(
          hasInterface: () async => true,
          probe: () async => true,
          resultCacheTtl: Duration.zero,
        ),
        syncTimestampService: SyncTimestampService(),
      );

      final result = await repo.getNearestCenters(
        latitude: 13.20,
        longitude: 123.5,
      );
      final centers = (result as Success).value;
      expect(centers.map((c) => c.id), [2, 1]);
      expect(centers.first.currentOccupancy, 2);
      expect(api.calls, isNot(contains('public/evacuation-centers/nearest')));
    },
  );
}
