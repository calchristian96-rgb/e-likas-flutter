import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elikas_mobile/core/localization/framework_localizations_fallback.dart';
import 'package:elikas_mobile/features/ec_board/presentation/pages/add_evacuee_form_page.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/lookup_entities.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/lookup_providers.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';

/// Add evacuee -> New family's "Home barangay": where the family lives,
/// not where the center is -- no default, required, with a "Same as this
/// center" shortcut. Same field as the web dashboard's Add Evacuee.
Widget _app(Widget home) => ProviderScope(
  overrides: [
    barangaysProvider.overrideWith(
      (ref) async => const [
        Barangay(id: 4, name: 'Bacong'),
        Barangay(id: 55, name: 'Tupas'),
      ],
    ),
    evacuationCentersLookupProvider.overrideWith(
      (ref) async => const [
        EvacuationCenterLookup(
          id: 1,
          name: 'Bacong Multipurpose Gymnasium',
          barangayId: 4,
          status: 'active',
        ),
      ],
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

Future<void> _newFamilyForm(WidgetTester tester) async {
  _tallPhone(tester);
  await tester.pumpWidget(
    _app(const AddEvacueeFormPage(centerId: 1, evacuationEventId: 7)),
  );
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.widgetWithText(ChoiceChip, 'Adult'));
  await _tapVisible(tester, find.widgetWithText(ChoiceChip, 'Female'));
  await _tapVisible(tester, find.text('New family'));
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Family name'),
    'Rosario Magbanua',
  );
  await tester.pumpAndSettle();
}

int? _chosen(WidgetTester tester) => tester
    .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
    .value;

void main() {
  testWidgets('asks for the home barangay, with no default', (tester) async {
    await _newFamilyForm(tester);

    expect(find.text('Home barangay'), findsOneWidget);
    expect(find.text("Choose the family's home barangay..."), findsOneWidget);
    expect(
      find.text(
        'Where the family lives -- not necessarily where this center is.',
      ),
      findsOneWidget,
    );
    expect(_chosen(tester), isNull);
    expect(
      find.text('New family: Rosario Magbanua, (home barangay not chosen yet).'),
      findsOneWidget,
    );
  });

  testWidgets('saving without it says so, under the field and in the message', (
    tester,
  ) async {
    await _newFamilyForm(tester);

    await _tapVisible(tester, find.text('Save Evacuee'));

    expect(find.text("Choose the family's home barangay."), findsNWidgets(2));
    expect(find.byType(AddEvacueeFormPage), findsOneWidget);
  });

  testWidgets(
    '"Same as this center" picks the center\'s barangay; any other can be '
    'chosen instead',
    (tester) async {
      await _newFamilyForm(tester);

      await _tapVisible(tester, find.text('Same as this center (Bacong)'));
      expect(_chosen(tester), 4);
      expect(
        find.text('New family: Rosario Magbanua, Bacong.'),
        findsOneWidget,
      );

      await _tapVisible(tester, find.byType(DropdownButton<int>));
      await tester.tap(find.text('Tupas').last);
      await tester.pumpAndSettle();
      expect(_chosen(tester), 55);
      expect(find.text('New family: Rosario Magbanua, Tupas.'), findsOneWidget);
    },
  );
}
