// Checkpoint 1 of the "Ligao Map Sheet" redesign: the theme, the shared
// widgets and the resident shell, rendered from fixture data (no
// emulator). Refresh the screenshots with:
//   flutter test --update-goldens test/golden/map_sheet_checkpoint1_test.dart

import 'package:elikas_mobile/app/theme/app_theme.dart';
import 'package:elikas_mobile/core/error/result.dart';
import 'package:elikas_mobile/core/utils/philippine_time.dart';
import 'package:elikas_mobile/core/widgets/filter_chip_row.dart';
import 'package:elikas_mobile/core/widgets/map_sheet.dart';
import 'package:elikas_mobile/core/widgets/occupancy_progress.dart';
import 'package:elikas_mobile/core/widgets/stat_strip.dart';
import 'package:elikas_mobile/core/widgets/ui_kit.dart';
import 'package:elikas_mobile/features/alerts/presentation/providers/alerts_summary_provider.dart';
import 'package:elikas_mobile/features/barangay_status/data/barangay_outlines.dart';
import 'package:elikas_mobile/features/barangay_status/domain/barangay_status.dart';
import 'package:elikas_mobile/features/barangay_status/presentation/barangay_status_providers.dart';
import 'package:elikas_mobile/features/barangay_status/presentation/bulletin_strip.dart';
import 'package:elikas_mobile/features/barangay_status/presentation/resident_area.dart';
import 'package:elikas_mobile/features/evacuation_centers/domain/entities/evacuation_center.dart';
import 'package:elikas_mobile/features/evacuation_centers/domain/entities/evacuation_centers_snapshot.dart';
import 'package:elikas_mobile/features/evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import 'package:elikas_mobile/features/evacuation_centers/presentation/widgets/center_status_display.dart';
import 'package:elikas_mobile/features/home/presentation/pages/home_page.dart';
import 'package:elikas_mobile/features/home/presentation/providers/home_provider.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../helpers/fake_staff_auth.dart';
import '../helpers/sheet_fonts.dart';

const _phone = Size(412, 915);

EvacuationCenter _center(
  int id,
  String name,
  String status,
  double lat,
  double lng, {
  int capacity = 200,
  int? inside,
}) => EvacuationCenter(
  id: id,
  name: name,
  type: 'school',
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
  _center(
    1,
    'Binatagan Elementary School',
    'active',
    13.031,
    123.531,
    inside: 84,
  ),
  _center(2, 'Ligao Central Gym', 'nearly_full', 13.033, 123.536, inside: 176),
  _center(3, 'Bonga Covered Court', 'on_standby', 13.028, 123.529),
  _center(
    4,
    'Tuburan Barangay Hall',
    'full',
    13.036,
    123.54,
    capacity: 80,
    inside: 80,
  ),
  _center(5, 'Paulba Chapel', 'closed', 13.04, 123.52),
];

BarangayStatus _b(int id, String name, String status, String label) =>
    BarangayStatus(
      id: id,
      name: name,
      psgcCode: '0505080${id.toString().padLeft(2, '0')}',
      status: status,
      label: label,
    );

BarangayStatusBoard _board({required bool news}) => BarangayStatusBoard(
  eventName: news ? 'Typhoon Pepito' : null,
  eventStatus: news ? 'active' : null,
  barangays: [
    _b(
      13,
      'Binatagan',
      news ? 'preemptive_evacuation' : 'normal',
      news ? 'Preemptive evacuation' : 'Normal',
    ),
    _b(
      21,
      'Tuburan',
      news ? 'forced_evacuation' : 'normal',
      news ? 'Forced evacuation' : 'Normal',
    ),
    _b(30, 'Bonga', news ? 'watch' : 'normal', news ? 'Watch' : 'Normal'),
  ],
);

List<Override> _homeOverrides({required bool news}) {
  final board = _board(news: news);
  return [
    ...signedInAs(null),
    alertsSummaryProvider.overrideWith((ref) async => (latest: null, count: 0)),
    allEvacuationCentersProvider.overrideWith((ref) async => _centers),
    allEvacuationCentersSnapshotProvider.overrideWith(
      (ref) async =>
          EvacuationCentersSnapshot(centers: _centers, isFromCache: false),
    ),
    connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
    barangayStatusBoardProvider.overrideWith((ref) async => board),
    barangayOutlinesProvider.overrideWith((ref) async => const []),
    residentPositionProvider.overrideWith(
      (ref) async => const Success(LatLng(13.03, 123.53)),
    ),
    residentAreaProvider.overrideWith(
      (ref) async => ResidentArea(
        name: 'Binatagan',
        psgcCode: '050508013',
        status: board.barangays.first,
        board: board,
      ),
    ),
  ];
}

/// The resident shell as the router builds it: the bulletin strip on
/// top (only with news), the tab, the ruled bottom bar.
class _ShellPreview extends StatelessWidget {
  const _ShellPreview({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sheet = SheetPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Consumer(
        builder: (context, ref, _) {
          final hasNews = ref.watch(liveStatusNewsProvider) != null;
          return Column(
            children: [
              const BulletinStrip(),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: hasNews,
                  child: child,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: sheet.ground,
          border: Border(
            top: BorderSide(color: sheet.rule, width: Sheet.rule),
          ),
        ),
        child: NavigationBar(
          selectedIndex: 0,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.navHome.toUpperCase(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.notifications_outlined),
              label: l10n.navAlerts.toUpperCase(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              label: l10n.navMap.toUpperCase(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.phone_in_talk_outlined),
              label: l10n.navHotlines.toUpperCase(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              label: l10n.navSettings.toUpperCase(),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _app(
  Widget home, {
  required bool dark,
  List<Override> overrides = const [],
}) => ProviderScope(
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

/// Every shared piece on one sheet: type, actions, fields, filters, the
/// state vocabulary, plates and the live strip.
class _Components extends StatelessWidget {
  const _Components();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Map sheet'.toUpperCase())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const BulletinStrip(
            news: LiveStatusNews(
              orderedBarangays: 2,
              eventName: 'Typhoon Pepito',
            ),
          ),
          const MarginHead('Type'),
          const SheetTitle('Evacuation centers', size: 34),
          const SizedBox(height: 8),
          Text(
            'Public Sans explains: where to go, whether it has room, and '
            'whether an evacuation is ordered.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 4),
          const SheetCaption('Caption in Source Serif 4 italic, hydro blue.'),
          const MarginHead('Actions and fields'),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.directions_walk),
            label: Text(l10n.orderGoToCenter.toUpperCase()),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: Text('Show'.toUpperCase()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () {},
                  child: Text(l10n.viewAll.toUpperCase()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Family name',
              hintText: 'e.g. Reyes',
            ),
          ),
          const SizedBox(height: 12),
          FilterChipRow<String>(
            options: const ['all', 'active', 'nearly_full', 'full'],
            selected: 'all',
            labelBuilder: (s) =>
                s == 'all' ? 'All' : localizedCenterStatus(context, s),
            leadingBuilder: (s, selected) => s == 'all'
                ? null
                : CenterSymbol(
                    status: s,
                    size: 20,
                    stroke: selected ? SheetPalette.of(context).ground : null,
                  ),
            onSelected: (_) {},
          ),
          Row(
            children: [
              Checkbox(value: true, onChanged: (_) {}),
              const Text('Senior citizen'),
              const Spacer(),
              Switch(value: true, onChanged: (_) {}),
            ],
          ),
          const MarginHead('Center states'),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              for (final s in const [
                'active',
                'nearly_full',
                'full',
                'on_standby',
                'closed',
              ])
                CenterStateTag(
                  status: s,
                  label: localizedCenterStatus(context, s),
                  symbolSize: 24,
                ),
            ],
          ),
          const MarginHead('Barangay states'),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BarangayStateTag(status: 'normal', label: 'Normal'),
              BarangayStateTag(status: 'watch', label: 'Watch'),
              BarangayStateTag(
                status: 'flooding_reported',
                label: 'Flooding reported',
              ),
              BarangayStateTag(
                status: 'preemptive_evacuation',
                label: 'Preemptive evacuation',
              ),
              BarangayStateTag(
                status: 'forced_evacuation',
                label: 'Forced evacuation',
              ),
            ],
          ),
          const MarginHead('Plates'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Binatagan Elementary School',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const CenterStateTag(status: 'active', label: 'Active'),
                const SizedBox(height: 10),
                const OccupancyProgress(
                  current: 84,
                  capacity: 200,
                  percent: 42,
                  color: Sheet.centerActive,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const StatStrip(
            items: [
              StatItem('Families', '128'),
              StatItem('Persons', '472'),
              StatItem('Centers open', '9'),
              StatItem('Full', '2', alert: true),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Neatline(
                child: SizedBox(
                  width: 96,
                  height: 64,
                  child: ColoredBox(color: Sheet.paper2),
                ),
              ),
              SizedBox(width: 16),
              StationNo(1),
              SizedBox(width: 8),
              StationNo(2),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _shoot(
  WidgetTester tester,
  Widget app,
  String name, {
  Size size = _phone,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.view.padding = const FakeViewPadding(top: 48, bottom: 32);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  // Decode the logo for real, so every screenshot shows it.
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
  // Unmount so Home's minute timer is cancelled.
  await tester.pumpWidget(const SizedBox());
}

void main() {
  setUpAll(loadSheetFonts);
  // Saturday 28 Nov 2026, 9:41 AM in Manila, for every screenshot.
  setUp(() => deviceNow = () => DateTime.utc(2026, 11, 28, 1, 41));
  tearDown(() => deviceNow = DateTime.now);

  testWidgets('home, calm day (no strip)', (tester) async {
    await _shoot(
      tester,
      _app(
        const _ShellPreview(child: HomePage()),
        dark: false,
        overrides: _homeOverrides(news: false),
      ),
      'home_calm_light',
    );
  });

  testWidgets('home, evacuation ordered (strip shown)', (tester) async {
    await _shoot(
      tester,
      _app(
        const _ShellPreview(child: HomePage()),
        dark: false,
        overrides: _homeOverrides(news: true),
      ),
      'home_news_light',
    );
  });

  testWidgets('home, night sheet', (tester) async {
    await _shoot(
      tester,
      _app(
        const _ShellPreview(child: HomePage()),
        dark: true,
        overrides: _homeOverrides(news: true),
      ),
      'home_news_dark',
    );
  });

  testWidgets('components, light', (tester) async {
    await _shoot(
      tester,
      _app(const _Components(), dark: false),
      'components_light',
      size: const Size(412, 1500),
    );
  });

  testWidgets('components, night sheet', (tester) async {
    await _shoot(
      tester,
      _app(const _Components(), dark: true),
      'components_dark',
      size: const Size(412, 1500),
    );
  });
}
