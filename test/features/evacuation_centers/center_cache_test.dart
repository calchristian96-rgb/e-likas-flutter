import 'package:drift/native.dart';
import 'package:elikas_mobile/core/database/resident_database.dart';
import 'package:elikas_mobile/features/evacuation_centers/data/datasources/evacuation_centers_local_datasource.dart';
import 'package:elikas_mobile/features/evacuation_centers/data/models/evacuation_center_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row(int id, {int barangayId = 13}) => {
  'id': id,
  'name': 'Center $id',
  'type': 'school',
  'address': null,
  'barangay_id': barangayId,
  'barangay': 'Binatagan',
  'latitude': 13.1,
  'longitude': 123.4,
  'capacity_persons': 100,
  'current_occupancy': 6,
  'occupancy_percent': 6.0,
  'status': 'active',
};

void main() {
  late ResidentDatabase db;
  late EvacuationCentersLocalDatasource local;

  setUp(() {
    db = ResidentDatabase.forExecutor(NativeDatabase.memory());
    local = EvacuationCentersLocalDatasource(db);
  });
  tearDown(() => db.close());

  test('public rows carry barangay_id; /nearest string coordinates parse', () {
    final m = EvacuationCenterModel.fromJson({
      ..._row(1),
      'latitude': '13.1455727',
      'longitude': '123.49',
    });
    expect(m.barangayId, 13);
    expect(m.latitude, closeTo(13.1455727, 1e-9));
    expect(m.address, isNull);
  });

  test(
    'a full list replaces the cache: a center no longer listed leaves it',
    () async {
      await local.replaceCenters([
        EvacuationCenterModel.fromJson(_row(1)),
        EvacuationCenterModel.fromJson(_row(2)),
      ]);
      await local.replaceCenters([EvacuationCenterModel.fromJson(_row(2))]);
      final cached = await local.getCachedCenters();
      expect(cached.map((c) => c.id), [2]);
      expect(cached.single.barangayId, 13);
    },
  );
}
