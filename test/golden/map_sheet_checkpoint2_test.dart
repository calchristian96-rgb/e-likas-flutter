// Checkpoint 2 of the "Ligao Map Sheet" redesign: the resident and staff
// screens, rendered from fixture data (no emulator). Refresh with:
//   flutter test --update-goldens test/golden/map_sheet_checkpoint2_test.dart

import 'dart:io';

import 'package:elikas_mobile/app/theme/app_theme.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/cache/staff_read_cache.dart';
import 'package:elikas_mobile/core/network/staff_api_client.dart';
import 'package:elikas_mobile/core/utils/philippine_time.dart';
import 'package:elikas_mobile/features/alerts/domain/entities/alert.dart';
import 'package:elikas_mobile/features/alerts/presentation/pages/alerts_page.dart';
import 'package:elikas_mobile/features/alerts/presentation/providers/alerts_summary_provider.dart';
import 'package:elikas_mobile/features/app_update/data/app_update_repository.dart';
import 'package:elikas_mobile/features/app_update/presentation/providers/app_update_providers.dart';
import 'package:elikas_mobile/features/barangay_status/data/barangay_outlines.dart';
import 'package:elikas_mobile/features/barangay_status/domain/barangay_status.dart';
import 'package:elikas_mobile/features/barangay_status/presentation/barangay_status_providers.dart';
import 'package:elikas_mobile/features/barangay_status/presentation/resident_area.dart';
import 'package:elikas_mobile/features/emergency_hotlines/presentation/pages/emergency_hotlines_page.dart';
import 'package:elikas_mobile/features/evacuation_centers/domain/entities/evacuation_center.dart';
import 'package:elikas_mobile/features/evacuation_centers/presentation/pages/evacuation_center_details_page.dart';
import 'package:elikas_mobile/features/evacuation_centers/presentation/pages/evacuation_centers_list_page.dart';
import 'package:elikas_mobile/features/evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/lookup_providers.dart';
import 'package:elikas_mobile/features/home/presentation/providers/home_provider.dart';
import 'package:elikas_mobile/features/map/domain/entities/map_data.dart';
import 'package:elikas_mobile/features/map/presentation/pages/evacuation_map_page.dart';
import 'package:elikas_mobile/features/map/presentation/providers/map_provider.dart';
import 'package:elikas_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:elikas_mobile/features/staff_home/cswd_home_page.dart';
import 'package:elikas_mobile/features/staff_home/staff_home_page.dart';
import 'package:elikas_mobile/features/transfers/transfers.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_staff_api.dart';
import '../helpers/fake_staff_auth.dart';
import '../helpers/home_fixtures.dart';
import '../helpers/sheet_fonts.dart';
import '../helpers/transfer_fixtures.dart';

EvacuationCenter _center(
  int id,
  String name,
  String status, {
  int capacity = 200,
  int? inside,
  double lat = 13.03,
  double lng = 123.53,
}) => EvacuationCenter(
  id: id,
  name: name,
  type: 'school',
  address: 'Zone 2',
  barangay: 'Binatagan',
  barangayId: 13,
  latitude: lat,
  longitude: lng,
  capacityPersons: capacity,
  currentOccupancy: inside,
  occupancyPercent: inside == null ? null : inside * 100 / capacity,
  status: status,
);

final _centers = [
  _center(1, 'Binatagan Elementary School', 'active', inside: 84),
  _center(2, 'Ligao Central Gym', 'nearly_full', inside: 176,
      lat: 13.036, lng: 123.536),
  _center(3, 'Bonga Covered Court', 'on_standby', lat: 13.025, lng: 123.525),
  _center(4, 'Tuburan Barangay Hall', 'full', capacity: 80, inside: 80,
      lat: 13.04, lng: 123.545),
  _center(5, 'Paulba Chapel', 'closed', lat: 13.02, lng: 123.54),
];

final _alerts = [
  Alert(
    id: 31,
    title: 'Forced evacuation: Tuburan',
    message: 'Residents of Tuburan must go to their evacuation center now.',
    alertType: 'evacuation',
    status: 'sent',
    dateSent: DateTime(2026, 11, 28, 8, 15),
    severity: 'mandatory',
  ),
  Alert(
    id: 30,
    title: 'Typhoon Pepito: Signal No. 2',
    message: 'Secure your home and prepare your go-bag.',
    alertType: 'weather',
    status: 'sent',
    dateSent: DateTime(2026, 11, 27, 18, 0),
    severity: 'advisory',
  ),
  Alert(
    id: 29,
    title: 'Relief distribution schedule',
    message: 'Relief boxes are given at the barangay hall from 9 AM.',
    alertType: 'info',
    status: 'sent',
    dateSent: DateTime(2026, 11, 26, 9, 0),
    severity: 'info',
  ),
];

const _board = BarangayStatusBoard(
  eventName: 'Typhoon Pepito',
  eventStatus: 'active',
  barangays: [
    BarangayStatus(
      id: 13,
      name: 'Binatagan',
      status: 'watch',
      label: 'Watch',
    ),
  ],
);

List<Override> _resident() => [
  ...signedInAs(null),
  connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
  barangayStatusBoardProvider.overrideWith((ref) async => _board),
  barangayOutlinesProvider.overrideWith((ref) async => const []),
  residentAreaProvider.overrideWith((ref) async => null),
  allEvacuationCentersProvider.overrideWith((ref) async => _centers),
  alertsListProvider.overrideWith((ref) async => _alerts),
  installedAppInfoProvider.overrideWith(
    (ref) async => const InstalledAppInfo(version: '0.5.0', build: 10),
  ),
  updateSupportedProvider.overrideWithValue(false),
];

class _Online implements ConnectivityService {
  @override
  Future<bool> get hasConnection async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(Widget home, List<Override> overrides, {bool dark = false}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

Future<void> _shoot(
  WidgetTester tester,
  Widget app,
  String name, {
  double height = 915,
}) async {
  tester.view.physicalSize = Size(412, height) * 2;
  tester.view.devicePixelRatio = 2;
  tester.view.padding = const FakeViewPadding(top: 48, bottom: 32);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/cp2_$name.png'),
  );
  await tester.pumpWidget(const SizedBox());
}

void main() {
  setUpAll(loadSheetFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    deviceNow = () => DateTime.utc(2026, 11, 28, 1, 41);
  });
  tearDown(() => deviceNow = DateTime.now);

  group('resident', () {
    testWidgets('alerts', (tester) async {
      await _shoot(tester, _app(const AlertsListPage(), _resident()), 'alerts');
    });

    testWidgets('centers list', (tester) async {
      await _shoot(
        tester,
        _app(const EvacuationCentersListPage(), _resident()),
        'centers_list',
        height: 1300,
      );
    });

    testWidgets('center details', (tester) async {
      await _shoot(
        tester,
        _app(const EvacuationCenterDetailsPage(centerId: 2), [
          ..._resident(),
          centerByIdProvider(2).overrideWith((ref) async => _centers[1]),
          centerPhotoRefreshProvider(2).overrideWith((ref) async {}),
        ]),
        'center_details',
        height: 1300,
      );
    });

    testWidgets('map', (tester) async {
      // flutter_map's tile cache asks path_provider for a folder; tiles
      // themselves never load in a test (no network), so the printed
      // sheet shows the map's paper ground under the symbols.
      final dir = Directory.systemTemp.createTempSync('elikas_map_');
      addTearDown(() => dir.deleteSync(recursive: true));
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => dir.path,
      );
      await _shoot(
        tester,
        _app(const EvacuationMapPage(), [
          ..._resident(),
          mapDataProvider.overrideWith(
            (ref) async => MapData(centers: _centers, hazardAreas: const []),
          ),
        ]),
        'map',
      );
    });

    testWidgets('hotlines', (tester) async {
      await _shoot(
        tester,
        _app(const EmergencyHotlinesPage(), _resident()),
        'hotlines',
        height: 1500,
      );
    });

    testWidgets('settings', (tester) async {
      await _shoot(
        tester,
        _app(const SettingsPage(), _resident()),
        'settings',
        height: 1500,
      );
    });

    testWidgets('settings, night sheet', (tester) async {
      await _shoot(
        tester,
        _app(const SettingsPage(), _resident(), dark: true),
        'settings_dark',
        height: 1500,
      );
    });
  });

  group('staff', () {
    testWidgets('barangay official home', (tester) async {
      await _shoot(
        tester,
        _app(const StaffHomePage(), homeOverrides(official)),
        'staff_official_home',
        height: 1800,
      );
    });

    testWidgets('barangay official home, night sheet', (tester) async {
      await _shoot(
        tester,
        _app(const StaffHomePage(), homeOverrides(official), dark: true),
        'staff_official_home_dark',
        height: 1800,
      );
    });

    testWidgets('CSWD home', (tester) async {
      await _shoot(
        tester,
        _app(const StaffHomePage(), homeOverrides(cswd)),
        'staff_cswd_home',
        height: 1800,
      );
    });

    testWidgets('CSWD barangay detail', (tester) async {
      await _shoot(
        tester,
        _app(const CswdBarangayDetailPage(barangayId: 13), [
          ...homeOverrides(cswd),
          staffApiClientProvider.overrideWithValue(FakeStaffApi()),
          connectivityServiceProvider.overrideWithValue(_Online()),
        ]),
        'staff_cswd_barangay',
        height: 1500,
      );
    });

    testWidgets('transfers', (tester) async {
      await _shoot(
        tester,
        _app(const TransfersPage(), [
          ...signedInAs(official),
          staffReadCacheProvider.overrideWithValue(
            FakeReadCache({
              ...homeAnswers,
              '/transfer-requests': transferRequestsAnswer,
            }),
          ),
          evacuationEventsLookupProvider.overrideWith((ref) async => const []),
          staffApiClientProvider.overrideWithValue(FakeStaffApi()),
          connectivityServiceProvider.overrideWithValue(_Online()),
          connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
        ]),
        'staff_transfers',
        height: 1500,
      );
    });
  });
}
