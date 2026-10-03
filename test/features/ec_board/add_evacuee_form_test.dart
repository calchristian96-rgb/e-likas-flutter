import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elikas_mobile/core/localization/framework_localizations_fallback.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/age_bracket.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/ec_board_entry_draft.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/per_person_sectoral_flag.dart';
import 'package:elikas_mobile/features/ec_board/presentation/pages/add_evacuee_form_page.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/lookup_entities.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/lookup_providers.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';

Widget _app(Widget home) => ProviderScope(
  overrides: [
    barangaysProvider.overrideWith(
      (ref) async => const [Barangay(id: 13, name: 'Binatagan')],
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
    home: home,
  ),
);

/// A phone-width screen tall enough that the lazily-built form list has
/// every section built at once.
void _tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 5000);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the sectoral section is collapsed by default and only adds what is ticked',
    (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(
        _app(const AddEvacueeFormPage(centerId: 1, evacuationEventId: 7)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sectoral details (optional)'), findsOneWidget);
      // Collapsed: none of the six options are on screen yet.
      expect(find.widgetWithText(FilterChip, 'Pregnant'), findsNothing);

      await _tapVisible(tester, find.text('Sectoral details (optional)'));
      // The person's own labels, as on the web form — not the board's
      // row names ("Pregnant Women").
      for (final label in [
        'PWD',
        'Pregnant',
        'Lactating',
        'Solo Parent',
        'Indigenous Person',
        '4Ps Beneficiary',
      ]) {
        expect(
          find.widgetWithText(FilterChip, label),
          findsOneWidget,
          reason: label,
        );
      }

      await _tapVisible(tester, find.widgetWithText(ChoiceChip, 'Female'));
      await _tapVisible(tester, find.widgetWithText(FilterChip, 'Pregnant'));
      expect(find.text('1 ticked'), findsOneWidget);
      expect(find.text('Sectoral: Pregnant.'), findsOneWidget);

      // Switching to male hides pregnant/lactating AND clears the tick.
      await _tapVisible(tester, find.widgetWithText(ChoiceChip, 'Male'));
      expect(find.widgetWithText(FilterChip, 'Pregnant'), findsNothing);
      expect(find.widgetWithText(FilterChip, 'Lactating'), findsNothing);
      expect(find.text('1 ticked'), findsNothing);
      expect(find.text('No sectoral details.'), findsOneWidget);
    },
  );

  testWidgets(
    'the pinned read-back steps aside while the keyboard is open',
    (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(
        _app(const AddEvacueeFormPage(centerId: 1, evacuationEventId: 7)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Will be recorded'), findsOneWidget);

      tester.view.viewInsets = const FakeViewPadding(bottom: 800);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(find.text('Will be recorded'), findsNothing);

      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(find.text('Will be recorded'), findsOneWidget);
    },
  );

  testWidgets(
    'editing an entry with flags opens the section with them ticked',
    (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(
        _app(
          const AddEvacueeFormPage(
            centerId: 1,
            evacuationEventId: 7,
            editingLocalId: 'abc',
            initialHouseholdLabel: 'Santos family',
            initialDraft: EcBoardEntryDraft(
              evacuationCenterId: 1,
              evacuationEventId: 7,
              sex: 'female',
              ageBracket: AgeBracket.adult,
              householdMode: HouseholdMode.existing,
              existingFamilyRemoteId: 42,
              sectoralFlags: {
                PerPersonSectoralFlag.pwd,
                PerPersonSectoralFlag.lactating,
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 ticked'), findsOneWidget);
      FilterChip chip(String label) =>
          tester.widget<FilterChip>(find.widgetWithText(FilterChip, label));
      expect(chip('PWD').selected, isTrue);
      expect(chip('Lactating').selected, isTrue);
      expect(chip('Pregnant').selected, isFalse);
      expect(
        find.text('Joins the family already here: Santos family.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'new family: this person is the head by default; unticking asks '
    'about the actual head, and the read-back follows every answer',
    (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(
        _app(const AddEvacueeFormPage(centerId: 1, evacuationEventId: 7)),
      );
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.widgetWithText(ChoiceChip, 'Teenage'));
      await _tapVisible(tester, find.widgetWithText(ChoiceChip, 'Male'));
      await _tapVisible(tester, find.text('New family'));

      final headTick = find.widgetWithText(
        CheckboxListTile,
        'This person is the family head',
      );
      expect(tester.widget<CheckboxListTile>(headTick).value, isTrue);
      expect(find.text('About the actual family head'), findsNothing);
      expect(
        find.text(
          "This person's age and sex will be used for the family head.",
        ),
        findsOneWidget,
      );
      expect(find.text('Head: this person (a minor).'), findsOneWidget);
      expect(find.text('Single-headed: not yet known.'), findsOneWidget);

      await _tapVisible(tester, headTick);
      expect(find.text('About the actual family head'), findsOneWidget);
      expect(
        find.text(
          'Head: someone else, sex not yet known, minor or not: not yet known.',
        ),
        findsOneWidget,
      );

      // Head's sex → Female; head is a minor → No.
      final inset = find.ancestor(
        of: find.text('About the actual family head'),
        matching: find.byType(Container),
      );
      await _tapVisible(
        tester,
        find.descendant(
          of: inset.first,
          matching: find.widgetWithText(ChoiceChip, 'Female'),
        ),
      );
      await _tapVisible(
        tester,
        find.descendant(
          of: inset.first,
          matching: find.widgetWithText(ChoiceChip, 'No'),
        ),
      );
      expect(
        find.text('Head: someone else, female, not a minor.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'already here: a family with no head linked offers linking this '
    'person as its head',
    (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(
        _app(
          const AddEvacueeFormPage(
            centerId: 1,
            evacuationEventId: 7,
            editingLocalId: 'abc',
            initialHouseholdLabel: 'Juan Dela Cruz',
            initialDraft: EcBoardEntryDraft(
              evacuationCenterId: 1,
              evacuationEventId: 7,
              sex: 'male',
              ageBracket: AgeBracket.adult,
              householdMode: HouseholdMode.existing,
              existingFamilyRemoteId: 454,
              headIsSelf: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tick = find.widgetWithText(
        CheckboxListTile,
        'This person is the family head',
      );
      expect(tick, findsOneWidget);
      expect(tester.widget<CheckboxListTile>(tick).value, isTrue);
      expect(
        find.text('This family has no head linked yet.'),
        findsOneWidget,
      );
      expect(
        find.text("Becomes that family's head (not a minor)."),
        findsOneWidget,
      );
      // The new-family questions never appear for Already here.
      expect(
        find.text('Only one family head? (single-headed)'),
        findsNothing,
      );
    },
  );
}
