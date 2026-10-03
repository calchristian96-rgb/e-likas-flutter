import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elikas_mobile/app/theme/app_theme.dart';
import 'package:elikas_mobile/core/error/failure.dart';
import 'package:elikas_mobile/core/error/result.dart';
import 'package:elikas_mobile/core/localization/framework_localizations_fallback.dart';
import 'package:elikas_mobile/features/registered_families/domain/entities/family_record.dart';
import 'package:elikas_mobile/features/registered_families/domain/entities/registered_family.dart';
import 'package:elikas_mobile/features/registered_families/presentation/providers/registered_families_provider.dart';
import 'package:elikas_mobile/features/registered_families/presentation/widgets/registered_family_detail_sheet.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';

const _family = RegisteredFamily(
  id: 7,
  barangayId: 13,
  barangayName: 'Binatagan',
  headOfFamilyName: 'Santos',
  memberCount: 3,
);

/// A stand-in for the server: who is still checked in, which check-outs
/// to refuse, and every check-out call the sheet made.
class _Server {
  _Server({required this.checkedIn, this.refuse = const {}});

  final Set<int> checkedIn;
  final Map<int, Failure> refuse;
  final calls = <(int, CheckOutReason)>[];

  /// When set, every check-out waits for it: the "still working" state.
  Completer<void>? gate;

  FamilyRecord record() => FamilyRecord(
    id: _family.id,
    hasHeadLinked: true,
    isLegacyBulkEntry: false,
    members: [
      _member(1, 'Maria Santos', isHead: true),
      _member(2, ''),
      _member(3, 'Pedro Santos'),
    ],
  );

  FamilyRecordMember _member(int id, String name, {bool isHead = false}) =>
      FamilyRecordMember(
        id: id,
        fullName: name,
        isPlaceholder: name.isEmpty,
        isHead: isHead,
        hasOpenStay: checkedIn.contains(id),
        openStayCenterName: checkedIn.contains(id) ? 'Binatagan Chapel' : null,
      );

  Future<Result<void>> checkOut(int id, CheckOutReason reason) async {
    calls.add((id, reason));
    await gate?.future;
    final failure = refuse[id];
    if (failure != null) return Failed(failure);
    checkedIn.remove(id);
    return const Success(null);
  }
}

Widget _app(_Server server) => ProviderScope(
  overrides: [
    familyRecordProvider(
      _family.id,
    ).overrideWith((ref) async => server.record()),
    checkOutEvacueeProvider.overrideWithValue(server.checkOut),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      FallbackMaterialLocalizationsDelegate(),
      FallbackCupertinoLocalizationsDelegate(),
      FallbackWidgetsLocalizationsDelegate(),
    ],
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showRegisteredFamilyDetailSheet(context, _family),
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

Future<void> _openSheet(WidgetTester tester, _Server server) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(server));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

final _sheetButton = find.widgetWithText(
  OutlinedButton,
  'Mark family as departed',
);
Finder _inDialog(Finder finder) =>
    find.descendant(of: find.byType(AlertDialog), matching: finder);
Finder _tickBox(String name) =>
    _inDialog(find.widgetWithText(CheckboxListTile, name));

void main() {
  testWidgets('the button only shows while someone is still checked in', (
    tester,
  ) async {
    await _openSheet(tester, _Server(checkedIn: {}));
    expect(find.text('Maria Santos'), findsOneWidget);
    expect(_sheetButton, findsNothing);
  });

  testWidgets(
    'lists only who is still checked in, all ticked; checks out the ticked '
    'ones with the one reason picked, then refreshes the members',
    (tester) async {
      final server = _Server(checkedIn: {1, 2});
      await _openSheet(tester, server);
      expect(_sheetButton, findsOneWidget);

      await tester.tap(_sheetButton);
      await tester.pumpAndSettle();

      // Pedro is already checked out, so he isn't offered.
      expect(_tickBox('Maria Santos'), findsOneWidget);
      expect(_tickBox('Member 2 (details pending)'), findsOneWidget);
      expect(_inDialog(find.text('Pedro Santos')), findsNothing);
      expect(
        _inDialog(find.text('Head of Family · Checked in at Binatagan Chapel')),
        findsOneWidget,
      );
      for (final name in ['Maria Santos', 'Member 2 (details pending)']) {
        expect(
          tester.widget<CheckboxListTile>(_tickBox(name)).value,
          isTrue,
          reason: '$name starts ticked',
        );
      }
      expect(_inDialog(find.text('Mark 2 as departed')), findsOneWidget);

      // Untick Maria, pick Others.
      await tester.tap(_tickBox('Maria Santos'));
      await tester.tap(_inDialog(find.text('Others')));
      await tester.pumpAndSettle();
      expect(_inDialog(find.text('Mark 1 as departed')), findsOneWidget);
      await tester.tap(_inDialog(find.text('Mark 1 as departed')));
      await tester.pumpAndSettle();

      // Confirm step, with the reason spelled out; nothing sent yet.
      expect(find.text('Mark 1 member as departed?'), findsOneWidget);
      expect(
        find.text(
          "They'll be recorded as departed for another reason and no longer "
          'count as here now.',
        ),
        findsOneWidget,
      );
      expect(server.calls, isEmpty);
      await tester.tap(_inDialog(find.text('Mark as departed')));
      await tester.pumpAndSettle();

      expect(server.calls, [(2, CheckOutReason.other)]);
      expect(find.text('1 member marked as departed.'), findsOneWidget);
      // The refreshed record: Maria still here, the button still offered.
      expect(find.text('Checked in at Binatagan Chapel'), findsOneWidget);
      expect(find.text('Checked out'), findsNWidgets(2));
      expect(_sheetButton, findsOneWidget);
    },
  );

  testWidgets('cancelling the confirmation checks no one out', (tester) async {
    final server = _Server(checkedIn: {1, 2});
    await _openSheet(tester, server);
    await tester.tap(_sheetButton);
    await tester.pumpAndSettle();
    await tester.tap(_inDialog(find.text('Mark 2 as departed')));
    await tester.pumpAndSettle();
    expect(find.text('Mark 2 members as departed?'), findsOneWidget);
    await tester.tap(_inDialog(find.text('Cancel')));
    await tester.pumpAndSettle();
    expect(server.calls, isEmpty);
    expect(find.text('Checked in at Binatagan Chapel'), findsNWidgets(2));
  });

  testWidgets(
    'while checking out, the confirmation says Marking… and cannot be '
    'closed',
    (tester) async {
      final server = _Server(checkedIn: {1, 2})..gate = Completer<void>();
      await _openSheet(tester, server);
      await tester.tap(_sheetButton);
      await tester.pumpAndSettle();
      await tester.tap(_inDialog(find.text('Mark 2 as departed')));
      await tester.pumpAndSettle();
      await tester.tap(_inDialog(find.text('Mark as departed')));
      await tester.pump();

      final working = find.widgetWithText(FilledButton, 'Marking…');
      expect(working, findsOneWidget);
      expect(tester.widget<FilledButton>(working).onPressed, isNull);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
            .onPressed,
        isNull,
      );
      // Neither the barrier nor Back closes it.
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Mark 2 members as departed?'), findsOneWidget);

      server.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(server.calls, hasLength(2));
      expect(find.text('2 members marked as departed.'), findsOneWidget);
    },
  );

  testWidgets('the submit button is off when no one is ticked', (tester) async {
    await _openSheet(tester, _Server(checkedIn: {1, 2}));
    await tester.tap(_sheetButton);
    await tester.pumpAndSettle();
    await tester.tap(_tickBox('Maria Santos'));
    await tester.tap(_tickBox('Member 2 (details pending)'));
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(FilledButton, 'Mark as departed');
    expect(submit, findsOneWidget);
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
  });

  testWidgets(
    'one refused check-out does not undo the others; it is listed by name',
    (tester) async {
      final server = _Server(
        checkedIn: {1, 2, 3},
        refuse: {3: const ServerFailure('Already checked out.')},
      );
      await _openSheet(tester, server);
      await tester.tap(_sheetButton);
      await tester.pumpAndSettle();
      await tester.tap(_inDialog(find.text('Mark 3 as departed')));
      await tester.pumpAndSettle();
      await tester.tap(_inDialog(find.text('Mark as departed')));
      await tester.pumpAndSettle();

      expect(server.calls, [
        (1, CheckOutReason.returnedHome),
        (2, CheckOutReason.returnedHome),
        (3, CheckOutReason.returnedHome),
      ]);
      expect(find.text('2 of 3 marked as departed'), findsOneWidget);
      expect(find.text("These weren't checked out:"), findsOneWidget);
      expect(find.text('Pedro Santos: Already checked out.'), findsOneWidget);
      await tester.tap(_inDialog(find.text('Close')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('2 members marked as departed.'), findsOneWidget);
    },
  );

  testWidgets('the single Check out also offers Others', (tester) async {
    final server = _Server(checkedIn: {1});
    await _openSheet(tester, server);
    await tester.tap(find.widgetWithText(TextButton, 'Check out'));
    await tester.pumpAndSettle();
    expect(find.text('Check out Maria Santos'), findsOneWidget);
    await tester.tap(_inDialog(find.text('Others')));
    await tester.pumpAndSettle();
    await tester.tap(_inDialog(find.widgetWithText(FilledButton, 'Check out')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Check out Maria Santos as departed for another reason? They'll no "
        'longer count as here now.',
      ),
      findsOneWidget,
    );
    await tester.tap(_inDialog(find.widgetWithText(FilledButton, 'Check out')));
    await tester.pumpAndSettle();
    expect(server.calls, [(1, CheckOutReason.other)]);
    expect(find.text('Maria Santos checked out.'), findsOneWidget);
  });
}
