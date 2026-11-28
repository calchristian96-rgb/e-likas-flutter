// The two screens officials use most during an evacuation, in the
// "Ligao Map Sheet" look: the EC board and Register family. Rendered from
// the same fixtures as their functional tests (no emulator). Refresh with:
//   flutter test --update-goldens test/golden/map_sheet_official_tools_test.dart
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:convert';

import 'package:elikas_mobile/app/theme/app_theme.dart';
import 'package:elikas_mobile/core/localization/framework_localizations_fallback.dart';
import 'package:elikas_mobile/core/utils/philippine_time.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/age_bracket.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/ec_board_quick_count.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/pending_ec_board_entry.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/per_person_sectoral_flag.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/sectoral_group.dart';
import 'package:elikas_mobile/features/ec_board/presentation/pages/ec_board_page.dart';
import 'package:elikas_mobile/features/ec_board/presentation/providers/ec_board_provider.dart';
import 'package:elikas_mobile/features/evacuation_centers/domain/entities/evacuation_center.dart';
import 'package:elikas_mobile/features/evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/family_registration_draft.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/lookup_entities.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/pending_registration_status.dart';
import 'package:elikas_mobile/features/family_registration/domain/repositories/pending_queue_repository.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/lookup_providers.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/pending_queue_provider.dart';
import 'package:elikas_mobile/features/family_registration/presentation/register/register_family_page.dart';
import 'package:elikas_mobile/features/home/presentation/providers/home_provider.dart';
import 'package:elikas_mobile/features/outbox/domain/pending_action.dart';
import 'package:elikas_mobile/features/outbox/presentation/outbox_providers.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/register_fixtures.dart';
import '../helpers/sheet_fonts.dart';

// --- EC board (the fixture of test/features/ec_board/ec_board_board_test.dart)

const _centerId = 5;
const _eventId = 13;

const _count = EcBoardQuickCount(
  familiesCumulative: 3,
  familiesNow: 4,
  personsCumulative: 9,
  personsNow: 8,
  beneficiaries4ps: 2,
  ageGroups: [
    EcBoardAgeGroupCount(
      ageBracket: AgeBracket.adult,
      maleCount: 5,
      femaleCount: 2,
    ),
    EcBoardAgeGroupCount(
      ageBracket: null,
      maleCount: 0,
      femaleCount: 0,
      totalCount: 1,
    ),
  ],
  ageGroupsTotal: EcBoardAgeGroupTotal(
    maleCount: 5,
    femaleCount: 2,
    totalPersons: 8,
  ),
  sectoralGroups: [
    EcBoardSectoralGroupCount(
      group: SectoralGroup.pwd,
      maleCount: 1,
      femaleCount: 0,
    ),
  ],
  isFromCache: false,
);

final _pending = PendingEcBoardEntrySummary(
  localId: 'p1',
  evacuationCenterId: _centerId,
  evacuationEventId: _eventId,
  status: PendingRegistrationStatus.pending,
  sex: 'female',
  ageBracket: AgeBracket.teenage,
  householdLabel: 'Santos household',
  createdAt: DateTime(2026, 11, 28, 8),
  updatedAt: DateTime(2026, 11, 28, 8),
  sectoralFlags: const {PerPersonSectoralFlag.pwd},
  headIsSelf: true,
  createsSingleHeadedHousehold: true,
  newHouseholdHeadSex: 'male',
);

List<Override> _ecBoard() => [
  evacuationEventsLookupProvider.overrideWith(
    (ref) async => const [
      EvacuationEventLookup(
        id: _eventId,
        name: 'Typhoon Pepito',
        status: 'active',
      ),
    ],
  ),
  ecBoardQuickCountProvider(
    _centerId,
    _eventId,
  ).overrideWith((ref) async => _count),
  ecBoardEntriesForCenterProvider(
    _centerId,
  ).overrideWith((ref) async => [_pending]),
  centerByIdProvider(_centerId).overrideWith(
    (ref) async => const EvacuationCenter(
      id: _centerId,
      name: 'Binatagan Central School',
      type: 'school',
      barangay: 'Binatagan',
      latitude: 13.2,
      longitude: 123.5,
      capacityPersons: 155,
      currentOccupancy: 8,
      status: 'active',
    ),
  ),
  connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
];

// --- Register family (the fixture of register_steps_test.dart)

class _Queue implements PendingQueueRepository {
  @override
  Future<String> enqueue(FamilyRegistrationDraft draft) async => 'local-1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoSync extends StaffSyncAll {
  _NoSync(super.ref);

  @override
  Future<OutboxRunResult> call({bool automatic = true}) async =>
      const OutboxRunResult();
}

List<Override> _register() => [
  ...registerOverrides,
  pendingQueueRepositoryProvider.overrideWithValue(_Queue()),
  staffSyncAllProvider.overrideWith(_NoSync.new),
];

Widget _app(Widget home, List<Override> overrides, {bool dark = false}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          FallbackMaterialLocalizationsDelegate(),
          FallbackCupertinoLocalizationsDelegate(),
          FallbackWidgetsLocalizationsDelegate(),
        ],
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

  testWidgets('EC board', (tester) async {
    await _shoot(
      tester,
      _app(const EcBoardPage(centerId: _centerId), _ecBoard()),
      'staff_ec_board',
      height: 2200,
    );
  });

  testWidgets('EC board, night sheet', (tester) async {
    await _shoot(
      tester,
      _app(const EcBoardPage(centerId: _centerId), _ecBoard(), dark: true),
      'staff_ec_board_dark',
      height: 2200,
    );
  });

  testWidgets('register family, step 1', (tester) async {
    await _shoot(
      tester,
      _app(const RegisterFamilyPage(), _register()),
      'staff_register_step1',
      height: 1300,
    );
  });

  testWidgets('register family, a saved draft', (tester) async {
    SharedPreferences.setMockInitialValues({
      'elikas.registerDraft.4': jsonEncode(registerDraft),
    });
    await _shoot(
      tester,
      _app(const RegisterFamilyPage(), _register()),
      'staff_register_draft',
      height: 1300,
    );
  });
}
