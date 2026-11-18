// Screenshot tests live outside test/, so the analyzer does not know they are tests.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:io';

import 'package:elikas_mobile/app/router/app_router.dart';
import 'package:elikas_mobile/core/error/result.dart';
import 'package:elikas_mobile/core/location/location_service.dart';
import 'package:elikas_mobile/core/network/staff_api_client.dart';
import 'package:elikas_mobile/features/alerts/presentation/providers/alerts_summary_provider.dart';
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

class _NoSync extends StaffSyncAll {
  _NoSync(super.ref);

  @override
  Future<OutboxRunResult> call() async => const OutboxRunResult();
}

class _Here implements LocationService {
  @override
  Future<Result<Position>> getCurrentPosition() async => Success(
    Position(
      latitude: 13.2,
      longitude: 123.5,
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
  locationServiceProvider.overrideWithValue(_Here()),
  allEvacuationCentersProvider.overrideWith((ref) async => const [_school]),
  nearestEvacuationCentersProvider(
    13.2,
    123.5,
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
];

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
    SharedPreferences.setMockInitialValues({});
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
      ]) {
    testWidgets(name, (tester) async {
      await shootRoute(
        tester,
        appRouter,
        location,
        name,
        overrides: [
          ...(session == null ? signedInAs(null) : homeOverrides(session)),
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
