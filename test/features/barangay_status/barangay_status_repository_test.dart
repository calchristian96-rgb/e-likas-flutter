import 'package:drift/native.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/database/resident_database.dart';
import 'package:elikas_mobile/core/sync/sync_timestamps.dart';
import 'package:elikas_mobile/features/barangay_status/data/barangay_status_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_api_client.dart';

const _body = {
  'success': true,
  'data': {
    'evacuation_event': {
      'name': 'DEMO - Typhoon Drill',
      'status': 'active',
      'is_drill': true,
    },
    'statuses': [],
    'barangays': [
      {
        'id': 13,
        'name': 'Binatagan',
        'psgc_code': '050508013',
        'status': 'forced_evacuation',
        'label': 'Forced evacuation',
      },
      {
        'id': 1,
        'name': 'Abella',
        'psgc_code': '050508001',
        'status': 'normal',
        'label': 'Normal',
      },
    ],
  },
};

void main() {
  late ResidentDatabase db;
  late FakeApiClient api;
  late bool online;
  late BarangayStatusRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = ResidentDatabase.forExecutor(NativeDatabase.memory());
    api = FakeApiClient({BarangayStatusRepository.path: _body});
    online = true;
    repo = BarangayStatusRepository(
      api,
      db,
      ConnectivityService.forTesting(
        hasInterface: () async => online,
        probe: () async => online,
        resultCacheTtl: Duration.zero,
      ),
      SyncTimestampService(),
    );
  });
  tearDown(() => db.close());

  test(
    'reads statuses, the drill flag, and keeps a copy for offline',
    () async {
      final live = await repo.getBoard();
      expect(live.isDrill, isTrue);
      expect(live.byId(13)!.label, 'Forced evacuation');
      expect(live.byId(13)!.rank, 4);
      expect(live.isFromCache, isFalse);

      online = false;
      final saved = await repo.getBoard();
      expect(saved.isFromCache, isTrue);
      expect(saved.isDrill, isTrue);
      expect(saved.byId(13)!.status, 'forced_evacuation');
      expect(saved.barangays.first.name, 'Abella'); // by name
    },
  );

  test('offline with nothing saved is an error the screen can show', () async {
    online = false;
    expect(repo.getBoard(), throwsStateError);
  });
}
