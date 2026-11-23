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
      'name': 'Typhoon Drill',
      'status': 'active',
      'is_drill': true,
    },
    'statuses': [],
    'mayon_zones': {'permanent_km': 6, 'extended_km': 7, 'buffer_km': 3},
    'barangays': [
      {
        'id': 13,
        'name': 'Binatagan',
        'psgc_code': '050508013',
        'status': 'forced_evacuation',
        'label': 'Forced evacuation',
        'flood': {
          'very_high_pct': 6.16,
          'high_pct': 5.57,
          'high_or_very_high_pct': 11.7,
        },
        'mayon': {
          'zone': 'outside',
          'label': '13.4 km from the summit',
          'nearest_km': 13.4,
          'to_extended_km': 6.4,
        },
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
      // Flood and Mayon are kept for offline too.
      expect(saved.byId(13)!.flood!.highOrVeryHighPct, 11.7);
      expect(saved.byId(13)!.mayon!.zone, 'outside');
      expect(saved.byId(1)!.mayon, isNull);
      expect(saved.mayonBufferKm, 3);
    },
  );

  test('offline with nothing saved is an error the screen can show', () async {
    online = false;
    expect(repo.getBoard(), throwsStateError);
  });
}
