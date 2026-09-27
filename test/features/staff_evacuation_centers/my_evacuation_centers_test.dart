import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elikas_mobile/app/theme/app_theme.dart';
import 'package:elikas_mobile/core/localization/framework_localizations_fallback.dart';
import 'package:elikas_mobile/features/evacuation_centers/domain/entities/evacuation_center.dart';
import 'package:elikas_mobile/features/evacuation_centers/domain/entities/evacuation_centers_snapshot.dart';
import 'package:elikas_mobile/features/evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import 'package:elikas_mobile/features/staff_auth/domain/entities/staff_session.dart';
import 'package:elikas_mobile/features/staff_auth/presentation/providers/staff_auth_provider.dart';
import 'package:elikas_mobile/features/staff_evacuation_centers/presentation/pages/staff_evacuation_centers_list_page.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';

class _SignedIn extends StaffAuth {
  _SignedIn(this.session);

  final StaffSession session;

  @override
  Future<StaffSession?> build() async => session;
}

const _official = StaffSession(
  id: 4,
  name: 'King Cris',
  email: 'k@example.com',
  role: 'barangay_official',
  roleDisplayName: 'Barangay Official',
  barangayId: 13,
  barangayName: 'Binatagan',
);

EvacuationCenter _center(int id, String name, String barangay, int occupancy) =>
    EvacuationCenter(
      id: id,
      name: name,
      type: 'school',
      barangay: barangay,
      latitude: 13.2,
      longitude: 123.5,
      capacityPersons: 100,
      currentOccupancy: occupancy,
      occupancyPercent: occupancy.toDouble(),
      status: 'active',
    );

final _centers = [
  _center(1, 'Binatagan Covered Court', 'Binatagan', 14),
  _center(2, 'Binatagan Chapel', 'Binatagan', 3),
  _center(3, 'Baligang Hall', 'Baligang', 40),
];

Widget _app(EvacuationCentersSnapshot snapshot, {StaffSession? session}) =>
    ProviderScope(
      overrides: [
        staffAuthProvider.overrideWith(() => _SignedIn(session ?? _official)),
        allEvacuationCentersSnapshotProvider.overrideWith(
          (ref) async => snapshot,
        ),
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
        home: const StaffEvacuationCentersListPage(),
      ),
    );

void main() {
  testWidgets(
    "lands straight on the official's own barangay's centers, with live "
    'occupancy and no saved-data notice',
    (tester) async {
      await tester.pumpWidget(
        _app(EvacuationCentersSnapshot(centers: _centers, isFromCache: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Binatagan Covered Court'), findsOneWidget);
      expect(find.text('Binatagan Chapel'), findsOneWidget);
      expect(find.text('Baligang Hall'), findsNothing);
      expect(find.text('14 / 100 (14%)'), findsOneWidget);
      expect(find.text('3 / 100 (3%)'), findsOneWidget);
      // No barangay step or grouping labels.
      expect(find.text('Your barangay'), findsNothing);
      expect(find.textContaining('Offline'), findsNothing);
      expect(find.textContaining('Caution'), findsNothing);
    },
  );

  testWidgets('says when it is showing the copy saved on this device', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        EvacuationCentersSnapshot(
          centers: _centers,
          isFromCache: true,
          lastSyncedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The app's standard OfflineBanner wording: "Offline • Last updated …".
    expect(find.textContaining('Offline'), findsOneWidget);
    expect(find.textContaining('2h ago'), findsOneWidget);
    expect(find.text('Binatagan Covered Court'), findsOneWidget);
  });

  testWidgets('a day-old saved copy is flagged as a caution', (tester) async {
    await tester.pumpWidget(
      _app(
        EvacuationCentersSnapshot(
          centers: _centers,
          isFromCache: true,
          lastSyncedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Caution'), findsOneWidget);
  });

  testWidgets('an account with no barangay sees every center', (tester) async {
    await tester.pumpWidget(
      _app(
        EvacuationCentersSnapshot(centers: _centers, isFromCache: false),
        session: const StaffSession(
          id: 1,
          name: 'CSWD',
          email: 'c@example.com',
          role: 'cswd_personnel',
          roleDisplayName: 'CSWD Personnel',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Baligang Hall'), findsOneWidget);
    expect(find.text('Binatagan Chapel'), findsOneWidget);
  });
}
