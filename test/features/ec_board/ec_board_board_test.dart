import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:elikas_mobile/app/theme/app_theme.dart';
import 'package:elikas_mobile/core/database/staff_database.dart';
import 'package:elikas_mobile/core/error/failure.dart';
import 'package:elikas_mobile/core/localization/framework_localizations_fallback.dart';
import 'package:elikas_mobile/features/ec_board/data/datasources/ec_board_local_datasource.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/age_bracket.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/ec_board_quick_count.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/pending_ec_board_entry.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/per_person_sectoral_flag.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/sectoral_group.dart';
import 'package:elikas_mobile/features/ec_board/presentation/pages/ec_board_page.dart';
import 'package:elikas_mobile/features/ec_board/presentation/providers/ec_board_provider.dart';
import 'package:elikas_mobile/features/evacuation_centers/domain/entities/evacuation_center.dart';
import 'package:elikas_mobile/features/evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/lookup_entities.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/pending_registration_status.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/lookup_providers.dart';
import 'package:elikas_mobile/features/home/presentation/providers/home_provider.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';

const _centerId = 5;
const _eventId = 13;

EcBoardQuickCount _count({bool fromCache = false, DateTime? fetchedAt}) =>
    EcBoardQuickCount(
      familiesCumulative: 3,
      familiesNow: 4,
      personsCumulative: 9,
      personsNow: 8,
      beneficiaries4ps: 2,
      ageGroups: const [
        EcBoardAgeGroupCount(
          ageBracket: AgeBracket.adult,
          maleCount: 5,
          femaleCount: 2,
        ),
        EcBoardAgeGroupCount(
          ageBracket: null, // the server's "unclassified" row
          maleCount: 0,
          femaleCount: 0,
          totalCount: 1,
        ),
      ],
      ageGroupsTotal: const EcBoardAgeGroupTotal(
        maleCount: 5,
        femaleCount: 2,
        totalPersons: 8,
      ),
      sectoralGroups: const [
        EcBoardSectoralGroupCount(
          group: SectoralGroup.pwd,
          maleCount: 1,
          femaleCount: 0,
        ),
      ],
      isFromCache: fromCache,
      fetchedAt: fetchedAt,
    );

PendingEcBoardEntrySummary _pending() => PendingEcBoardEntrySummary(
  localId: 'p1',
  evacuationCenterId: _centerId,
  evacuationEventId: _eventId,
  status: PendingRegistrationStatus.pending,
  sex: 'female',
  ageBracket: AgeBracket.teenage,
  householdLabel: 'Santos household',
  createdAt: DateTime(2026, 9, 28),
  updatedAt: DateTime(2026, 9, 28),
  sectoralFlags: const {PerPersonSectoralFlag.pwd},
  headIsSelf: true,
  createsSingleHeadedHousehold: true,
  newHouseholdHeadSex: 'male',
);

Future<void> _pump(
  WidgetTester tester, {
  required Future<EcBoardQuickCount> Function() count,
  List<PendingEcBoardEntrySummary> pending = const [],
  ThemeData? theme,
  double width = 360,
}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(width * 3, 3200 * 3);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        evacuationEventsLookupProvider.overrideWith(
          (ref) async => const [
            EvacuationEventLookup(
              id: _eventId,
              name: 'Typhoon Bagwis',
              status: 'active',
            ),
          ],
        ),
        ecBoardQuickCountProvider(
          _centerId,
          _eventId,
        ).overrideWith((ref) => count()),
        ecBoardEntriesForCenterProvider(
          _centerId,
        ).overrideWith((ref) async => pending),
        centerByIdProvider(_centerId).overrideWith(
          (ref) async => const EvacuationCenter(
            id: _centerId,
            name: 'Binatagan Central School',
            type: 'school',
            barangay: 'Binatagan',
            latitude: 13.2,
            longitude: 123.5,
            capacityPersons: 155,
            status: 'active',
          ),
        ),
        connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          FallbackMaterialLocalizationsDelegate(),
          FallbackCupertinoLocalizationsDelegate(),
          FallbackWidgetsLocalizationsDelegate(),
        ],
        home: const EcBoardPage(centerId: _centerId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

double _y(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text).first).dy;

void main() {
  final fetchedAt = DateTime(2026, 9, 28, 9, 5);

  testWidgets('the header follows the official template order and "As of" '
      'is when the figures arrived, not now', (tester) async {
    await _pump(tester, count: () async => _count(fetchedAt: fetchedAt));

    final order = [
      'Barangay',
      'Evacuation center',
      'Evacuation Event',
      'As of',
      'Families (Cum/Now)',
      'Persons (Cum/Now)',
      '4Ps Beneficiary Families',
    ];
    for (var i = 1; i < order.length; i++) {
      expect(
        _y(tester, order[i]),
        greaterThan(_y(tester, order[i - 1])),
        reason: '${order[i]} comes after ${order[i - 1]}',
      );
    }
    expect(find.text('Binatagan'), findsOneWidget);
    expect(find.text('Binatagan Central School'), findsOneWidget);
    expect(find.text('3 / 4'), findsOneWidget);
    expect(find.text('9 / 8'), findsOneWidget);
    expect(
      find.text(DateFormat.yMMMd().add_jm().format(fetchedAt)),
      findsOneWidget,
    );
    // Live: no offline note.
    expect(find.textContaining('Offline — showing'), findsNothing);
  });

  testWidgets('the two tables are one sheet on one grid: Age & Sex then '
      'Sectoral, with "Not yet classified" and all 8 sectoral rows', (
    tester,
  ) async {
    await _pump(tester, count: () async => _count(fetchedAt: fetchedAt));

    expect(
      _y(tester, 'Sectoral Group'),
      greaterThan(_y(tester, 'Age & Sex Disaggregation')),
    );
    expect(find.text('Not yet classified'), findsWidgets);
    for (final label in [
      'Persons with Disability',
      'Child-Headed Family',
      'Single-Headed Family',
      'Solo Parent',
      'Pregnant Women',
      'Lactating Mothers',
      '4Ps Beneficiary',
      'Indigenous Peoples',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    // The Total column lines up down the whole board: the Age & Sex
    // heading's "Total", the Age & Sex total figure (8) under it, and the
    // Sectoral heading's "Total" all end at the same x. ("Total" also
    // labels the Age & Sex total row, on the left — the headings are the
    // first and last matches.)
    final totals = find.text('Total');
    final column = tester.getTopRight(totals.first).dx;
    expect(tester.getTopRight(totals.last).dx, column);
    expect(tester.getTopRight(find.text('8').first).dx, column);
  });

  testWidgets('offline, "As of" keeps the saved time and says it is the '
      'saved copy', (tester) async {
    final savedAt = DateTime.now().subtract(const Duration(hours: 3));
    await _pump(
      tester,
      count: () async => _count(fromCache: true, fetchedAt: savedAt),
    );
    expect(
      find.text(DateFormat.yMMMd().add_jm().format(savedAt)),
      findsOneWidget,
    );
    expect(find.text('3h ago'), findsOneWidget);
    expect(find.textContaining('Offline — showing'), findsOneWidget);
  });

  testWidgets('a board never fetched says so and shows dashes, not zeros', (
    tester,
  ) async {
    await _pump(
      tester,
      count: () async => throw const NetworkFailure('offline'),
    );
    expect(find.text('Not yet fetched'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('pending entries sit in their own section as +N, never added '
      'into the board', (tester) async {
    await _pump(
      tester,
      count: () async => _count(fetchedAt: fetchedAt),
      pending: [_pending()],
    );
    expect(find.text('Added on this device'), findsOneWidget);
    expect(find.text('+1'), findsWidgets);
    // At 360dp this long sectoral label wraps onto two lines while its
    // three +N columns remain aligned and visible.
    expect(
      tester.getSize(find.text('Single-Headed Family').last).height,
      greaterThan(20),
    );
    expect(
      _y(tester, 'Added on this device'),
      greaterThan(_y(tester, 'Indigenous Peoples')),
    );
    // The board's Age & Sex total is still the server's 8.
    expect(find.text('8'), findsWidgets);
    expect(find.text('9'), findsNothing);
  });

  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    testWidgets('$name mode at 360dp: no overflow, and text uses the '
        'theme\'s own colors', (tester) async {
      await _pump(
        tester,
        count: () async => _count(fetchedAt: fetchedAt),
        pending: [_pending()],
        theme: theme,
      );
      final value = tester.widget<Text>(find.text('Binatagan Central School'));
      expect(value.style?.color, theme.colorScheme.onSurface);
      final row = tester.widget<Text>(find.text('Solo Parent'));
      expect(row.style?.color, theme.colorScheme.onSurface);
    });
  }

  testWidgets('the tables stay stacked on a phone but sit side by side on '
      'a wide screen', (tester) async {
    await _pump(tester, count: () async => _count(fetchedAt: fetchedAt));
    expect(
      _y(tester, 'Sectoral Group'),
      greaterThan(_y(tester, 'Age & Sex Disaggregation')),
    );

    await _pump(
      tester,
      count: () async => _count(fetchedAt: fetchedAt),
      width: 1000,
    );
    // Same band: the two title texts differ only by a few px of line
    // height, where stacked they are hundreds of px apart.
    expect(
      _y(tester, 'Sectoral Group'),
      closeTo(_y(tester, 'Age & Sex Disaggregation'), 20),
    );
  });

  test('the saved copy carries the time it was saved as its "As of"', () async {
    final db = StaffDatabase.forExecutor(NativeDatabase.memory());
    addTearDown(db.close);
    final local = EcBoardLocalDataSource(db);
    final savedAt = DateTime(2026, 9, 28, 9, 5);

    await local.cacheQuickCount(
      centerId: _centerId,
      evacuationEventId: _eventId,
      count: _count(),
      cachedAt: savedAt,
    );
    final back = await local.getCachedQuickCount(
      centerId: _centerId,
      evacuationEventId: _eventId,
    );
    expect(back!.isFromCache, isTrue);
    expect(back.fetchedAt, savedAt);
    expect(back.familiesNow, 4);
  });
}
