import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elikas_mobile/core/error/failure.dart';
import 'package:elikas_mobile/core/localization/framework_localizations_fallback.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/family_here.dart';
import 'package:elikas_mobile/features/ec_board/presentation/pages/add_evacuee_form_page.dart';
import 'package:elikas_mobile/features/ec_board/presentation/providers/ec_board_provider.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/pending_queue_provider.dart';
import 'package:elikas_mobile/features/registered_families/domain/entities/registered_families_snapshot.dart';
import 'package:elikas_mobile/features/registered_families/domain/entities/registered_family.dart';
import 'package:elikas_mobile/features/registered_families/presentation/providers/registered_families_provider.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';

/// Add evacuee's "Already here" offers the families here right now, from
/// the server -- the same list as the web dashboard: another barangay's
/// family as "Family #N · (its barangay) · X here". Offline, this
/// device's saved families stand in, said as such.
const _here = [
  FamilyHere(
    id: 2,
    isGeneric: false,
    name: 'Ana Reyes',
    barangayName: 'Bacong',
    memberCount: 4,
    headLinked: true,
  ),
  FamilyHere(
    id: 16,
    isGeneric: true,
    barangayName: 'Tupas',
    hereCount: 2,
    memberCount: 3,
    headLinked: true,
  ),
  FamilyHere(
    id: 17,
    isGeneric: true,
    barangayName: 'Tupas',
    hereCount: 1,
    memberCount: 1,
    headLinked: false,
  ),
];

Widget _app({
  required Future<List<FamilyHere>> Function() here,
  List<RegisteredFamily> saved = const [],
}) => ProviderScope(
  overrides: [
    ecBoardFamiliesHereProvider(1, 7).overrideWith((ref) => here()),
    ecBoardPendingNewHouseholdsProvider(1, 7).overrideWith((ref) async => []),
    pendingRegistrationsProvider.overrideWith((ref) async => []),
    registeredFamiliesProvider.overrideWith(
      (ref) async => RegisteredFamiliesSnapshot(
        families: saved,
        isFromCache: true,
        lastSyncedAtEpochMs: null,
      ),
    ),
  ],
  child: MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      FallbackMaterialLocalizationsDelegate(),
      FallbackCupertinoLocalizationsDelegate(),
      FallbackWidgetsLocalizationsDelegate(),
    ],
    home: const AddEvacueeFormPage(centerId: 1, evacuationEventId: 7),
  ),
);

Future<void> _openPicker(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = const Size(1080, 5000);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Select family'));
  await tester.pumpAndSettle();
}

void main() {
  test('reads the server rows, named and not', () {
    final named = FamilyHere.fromJson({
      'id': 2,
      'name': null,
      'head_of_family': {'id': 9, 'full_name': 'Ana Reyes'},
      'barangay': {'id': 4, 'name': 'Bacong'},
      'member_count': 4,
    });
    expect(
      [named.isGeneric, named.name, named.barangayName, named.headLinked],
      [false, 'Ana Reyes', 'Bacong', true],
    );

    final generic = FamilyHere.fromJson({
      'id': 16,
      'is_generic': true,
      'barangay': {'id': 55, 'name': 'Tupas'},
      'here_count': 2,
      'member_count': 3,
      'has_head_linked': false,
      'name': null,
      'head_of_family': null,
      'home_address': null,
    });
    expect(
      [generic.isGeneric, generic.name, generic.hereCount, generic.headLinked],
      [true, null, 2, false],
    );
  });

  testWidgets('lists the families here, another barangay\'s by number', (
    tester,
  ) async {
    await _openPicker(tester, _app(here: () async => _here));

    expect(find.text('Ana Reyes'), findsOneWidget);
    expect(find.text('Family #16 · Tupas · 2 here'), findsOneWidget);
    expect(find.text('Family #17 · Tupas · 1 here'), findsOneWidget);
    expect(find.text('Up to date'), findsOneWidget);

    await tester.tap(find.text('Family #16 · Tupas · 2 here'));
    await tester.pumpAndSettle();
    // The pick, by its label; its head is linked, so no head tick.
    expect(find.text('Family #16 · Tupas · 2 here'), findsOneWidget);
    expect(
      find.text('Joins the family already here: Family #16 · Tupas · 2 here.'),
      findsOneWidget,
    );
    expect(find.text('This person is the family head'), findsNothing);
  });

  testWidgets('a family here with no head linked offers this person as head', (
    tester,
  ) async {
    await _openPicker(tester, _app(here: () async => _here));
    await tester.tap(find.text('Family #17 · Tupas · 1 here'));
    await tester.pumpAndSettle();
    expect(find.text('This person is the family head'), findsOneWidget);
  });

  testWidgets('none here says so', (tester) async {
    await _openPicker(tester, _app(here: () async => const []));
    expect(find.text('No families here right now.'), findsOneWidget);
  });

  testWidgets('offline, the families saved on this phone stand in, said so', (
    tester,
  ) async {
    await _openPicker(
      tester,
      _app(
        here: () async => throw const NetworkFailure('offline'),
        saved: const [
          RegisteredFamily(
            id: 30,
            barangayId: 4,
            barangayName: 'Bacong',
            headOfFamilyName: 'Jose Mercado',
            memberCount: 3,
          ),
        ],
      ),
    );

    expect(find.text('Jose Mercado'), findsOneWidget);
    expect(
      find.text(
        'Offline: showing the families saved on this phone. One that has '
        'left this center will be refused when it syncs.',
      ),
      findsOneWidget,
    );
    expect(find.text('Up to date'), findsNothing);
  });
}
