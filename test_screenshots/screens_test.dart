// Screenshot tests live outside test/, so the analyzer does not know they are tests.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:io';

import 'package:elikas_mobile/app/router/app_router.dart';
import 'package:elikas_mobile/core/error/result.dart';
import 'package:elikas_mobile/core/location/location_service.dart';
import 'package:elikas_mobile/core/network/staff_api_client.dart';
import 'package:elikas_mobile/features/alerts/presentation/providers/alerts_summary_provider.dart';
import 'package:elikas_mobile/features/barangay_status/data/barangay_outlines.dart';
import 'package:elikas_mobile/features/barangay_status/domain/barangay_status.dart';
import 'package:elikas_mobile/features/barangay_status/presentation/barangay_status_providers.dart';
import 'package:elikas_mobile/features/evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/env/backend_override_service.dart';
import 'package:elikas_mobile/features/evacuation_centers/domain/entities/evacuation_center.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/lookup_entities.dart';
import 'package:elikas_mobile/features/home/presentation/providers/home_provider.dart';
import 'package:elikas_mobile/features/staff_evacuation_centers/presentation/providers/own_centers_provider.dart';
import 'package:elikas_mobile/features/outbox/domain/pending_action.dart';
import 'package:elikas_mobile/features/outbox/presentation/outbox_providers.dart';
import 'package:elikas_mobile/features/staff_auth/domain/entities/staff_session.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/fake_staff_api.dart';
import '../test/helpers/fake_staff_auth.dart';
import '../test/helpers/home_fixtures.dart';
import 'harness.dart';
import 'package:elikas_mobile/core/push/push_providers.dart';
import 'package:elikas_mobile/core/push/push_service.dart';

/// Push stays silent in screenshots: no Firebase, no permission prompt.
class _SilentPush implements PushBackend {
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> subscribe(String topic) async {}
  @override
  Future<void> unsubscribe(String topic) async {}
  @override
  Stream<PushMessage> get onForeground => const Stream.empty();
  @override
  Stream<PushMessage> get onOpened => const Stream.empty();
  @override
  Future<PushMessage?> initialMessage() async => null;
}

class _NoSync extends StaffSyncAll {
  _NoSync(super.ref);

  @override
  Future<OutboxRunResult> call() async => const OutboxRunResult();
}

class _Here implements LocationService {
  @override
  Future<Result<Position>> getCurrentPosition() async => Success(
    Position(
      // Inside Binatagan (Pob.) in the bundled boundaries.
      latitude: 13.24197,
      longitude: 123.52493,
      timestamp: DateTime(2026, 11, 17),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Binatagan extends ResidentBarangayNotifier {
  @override
  ResidentBarangay? build() =>
      const ResidentBarangay(id: 13, name: 'Binatagan');
}

const _school = EvacuationCenter(
  id: 71,
  name: 'Binatagan Elementary School',
  type: 'school',
  barangay: 'Binatagan',
  barangayId: 13,
  latitude: 13.21,
  longitude: 123.5,
  capacityPersons: 120,
  currentOccupancy: 48,
  status: 'active',
  distanceMeters: 650,
);

/// A resident in Binatagan under a preemptive evacuation, online.
final residentOverrides = <Override>[
  // The bundled boundaries, read here (asset loading is not reliable
  // across golden tests).
  barangayOutlinesProvider.overrideWith(
    (ref) async =>
        parseBarangayOutlines(File(barangayOutlinesAsset).readAsStringSync()),
  ),
  locationServiceProvider.overrideWithValue(_Here()),
  allEvacuationCentersProvider.overrideWith((ref) async => const [_school]),
  nearestEvacuationCentersProvider(
    13.24197,
    123.52493,
  ).overrideWith((ref) async => const [_school]),
  alertsSummaryProvider.overrideWith((ref) async => (latest: null, count: 0)),
  residentBarangayProvider.overrideWith(_Binatagan.new),
  barangayStatusBoardProvider.overrideWith(
    (ref) async => const BarangayStatusBoard(
      eventName: 'Typhoon Pepito',
      eventStatus: 'active',
      barangays: [
        BarangayStatus(
          id: 13,
          name: 'Binatagan',
          psgcCode: '050508013',
          status: 'preemptive_evacuation',
          label: 'Preemptive evacuation',
        ),
      ],
    ),
  ),
];

/// Online, nothing sent anywhere.
final offlineSafe = <Override>[
  connectivityServiceProvider.overrideWithValue(
    ConnectivityService.forTesting(
      hasInterface: () async => true,
      probe: () async => true,
    ),
  ),
  connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
  staffSyncAllProvider.overrideWith(_NoSync.new),
  staffApiClientProvider.overrideWithValue(FakeStaffApi()),
  pushServiceProvider.overrideWithValue(PushService(_SilentPush())),
];

/// What the 0.4.0 screens read (apps-api-2026-11-22.md sections 3, 5).
final newAnswers = <String, Map<String, dynamic>>{
  ...homeAnswers,
  '/families-to-evacuate': {
    'summary': {'families': 5, 'persons': 19, 'checked_in': 2},
    'can': {'manage': true, 'check_in': true},
    'families': [
      for (final (id, head, purok, status) in [
        (1, 'Maria Santos', 3, 'expected'),
        (2, 'Jose Cruz', 3, 'checked_in'),
        (3, 'Ana Reyes', 1, 'expected'),
        (4, 'Lito Bautista', 1, 'checked_in'),
        (5, 'Rosa Dela Cruz', null, 'expected'),
      ])
        {
          'id': id,
          'head': head,
          'members_count': 3 + id % 3,
          'purok': purok == null
              ? null
              : {
                  'id': purok,
                  'name': 'Purok $purok',
                  'is_high_risk': purok == 3,
                },
          'status': status,
          'from_past_event': id == 3,
        },
    ],
  },
  '/facility-requests': {
    'data': [
      {
        'id': 7,
        'evacuation_center': {'id': 71, 'name': 'Binatagan Elementary School'},
        'facility_type': 'toilet_female',
        'quantity_needed': 10,
        'quantity_approved': 6,
        'unit': 'pieces',
        'status': 'sent',
        'may_receive': true,
      },
      {
        'id': 8,
        'evacuation_center': {'id': 71, 'name': 'Binatagan Elementary School'},
        'item': 'Water containers',
        'quantity_needed': 20,
        'status': 'received',
      },
    ],
  },
  '/facility-requests/suggestions': {
    'suggestions': [
      {
        'center': {'id': 72, 'name': 'Binatagan Covered Court'},
        'facility_type': 'handwashing_facility',
        'label': 'handwashing stations',
        'quantity': 3,
        'unit': 'stations',
        'reason':
            'Short of the planning standard for a full center (60 persons): 3 handwashing stations.',
      },
    ],
  },
  '/monitoring/evacuees': {
    'evacuation_event': {
      'id': 24,
      'name': 'Typhoon Pepito',
      'status': 'active',
    },
    'data': {
      'barangays': [
        {
          'barangay': {'id': 13, 'name': 'Binatagan'},
          'families': 6,
          'persons': 22,
          'list': {'families': 12, 'persons': 47, 'checked_in': 5},
        },
        {
          'barangay': {'id': 49, 'name': 'Tomolin'},
          'families': 30,
          'persons': 101,
          'list': {'families': 32, 'persons': 110, 'checked_in': 28},
        },
        {
          'barangay': {'id': 4, 'name': 'Bay'},
          'families': 3,
          'persons': 9,
          'list': null,
        },
      ],
    },
  },
};

OwnCenter _center(int id, String name, String status, int occ, int cap) =>
    OwnCenter(
      center: EvacuationCenterLookup(
        id: id,
        name: name,
        barangayId: 13,
        status: status,
      ),
      public: EvacuationCenter(
        id: id,
        name: name,
        type: 'school',
        barangayId: 13,
        latitude: 13.2,
        longitude: 123.5,
        capacityPersons: cap,
        currentOccupancy: occ,
        status: status,
      ),
    );

final ownCenters = ownCentersProvider.overrideWith(
  (ref) async => [
    _center(71, 'Binatagan Elementary School', 'active', 48, 120),
    _center(72, 'Binatagan Covered Court', 'full', 80, 80),
    _center(73, 'Binatagan Chapel', 'on_standby', 0, 60),
  ],
);

void main() {
  setUpAll(loadFonts);
  setUp(() async {
    // The push permission reason was already shown.
    SharedPreferences.setMockInitialValues({'push_permission_asked_v1': true});
    await BackendOverrideService.initialize();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
  });

  // One shot each at 360x640 (font scale 1.0).
  for (final (name, location, session, extra)
      in <(String, String, StaffSession?, List<Override>)>[
        ('resident_home', '/home', null, residentOverrides),
        // A barangay official on the public view: the amber banner.
        ('public_signed_in', '/home', official, residentOverrides),
        ('settings', '/settings', official, const []),
        ('staff_more', '/staff/more', official, const []),
        ('ec_board', '/staff/centers', official, [ownCenters]),
        ('relief_boxes', '/staff/relief/round/1', official, const []),
        ('relief_overview', '/staff/relief', official, const []),
        ('cswd_barangays', '/staff/barangays', cswd, const []),
        ('transfers', '/staff/home/transfers', official, const []),
        ('private_houses', '/staff/home/private-houses/13', official, const []),
        ('cswd_barangay_detail', '/staff/barangays/13', cswd, const []),
        ('notifications', '/staff/home/notifications', cswd, const []),
        // 0.4.0.
        (
          'families_to_evacuate',
          '/staff/home/families-to-evacuate',
          official,
          [ownCenters],
        ),
        (
          'facility_requests',
          '/staff/home/facility-requests',
          official,
          [ownCenters],
        ),
        ('evacuation_progress', '/staff/home/progress', cswd, const []),
        ('report_problem', '/staff/more/report', official, const []),
        ('prepare', '/prepare', null, residentOverrides),
      ]) {
    testWidgets(name, (tester) async {
      await shootRoute(
        tester,
        appRouter,
        location,
        name,
        overrides: [
          ...(session == null
              ? signedInAs(null)
              : homeOverrides(session, answers: newAnswers)),
          ...offlineSafe,
          ...extra,
        ],
      );
    });
  }

  testWidgets('settings, scrolled to the end', (tester) async {
    await shootRoute(
      tester,
      appRouter,
      '/settings',
      'settings_bottom',
      overrides: [...homeOverrides(official), ...offlineSafe],
      before: (tester) =>
          tester.drag(find.byType(Scrollable).first, const Offset(0, -4000)),
    );
  });

  for (final scale in [1.0, 1.3]) {
    final suffix = scale == 1.0 ? '' : '_scale13';
    testWidgets('official home at $scale', (tester) async {
      await shootRoute(
        tester,
        appRouter,
        '/staff/home',
        'official_home$suffix',
        overrides: [...homeOverrides(official), ...offlineSafe],
        textScale: scale,
      );
    });
    testWidgets('cswd home at $scale', (tester) async {
      await shootRoute(
        tester,
        appRouter,
        '/staff/home',
        'cswd_home$suffix',
        overrides: [...homeOverrides(cswd), ...offlineSafe],
        textScale: scale,
      );
    });
  }
}
