import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elikas_mobile/core/localization/framework_localizations_fallback.dart';
import 'package:elikas_mobile/features/ec_board/presentation/pages/add_evacuee_form_page.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/lookup_entities.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/lookup_providers.dart';
import 'package:elikas_mobile/features/staff_auth/domain/entities/staff_session.dart';
import 'package:elikas_mobile/features/staff_auth/presentation/providers/staff_auth_provider.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';

/// Add evacuee reminds a barangay official at another barangay's center
/// to add only people staying there -- a note, never a block, as on the
/// web dashboard.
class _SignedIn extends StaffAuth {
  _SignedIn(this.session);

  final StaffSession session;

  @override
  Future<StaffSession?> build() async => session;
}

StaffSession _session(String role, int? barangayId) => StaffSession(
  id: 3,
  name: 'Pedro Reyes',
  email: 'brgy@example.test',
  role: role,
  roleDisplayName: role,
  barangayId: barangayId,
  barangayName: barangayId == 4 ? 'Bacong' : null,
);

Widget _app(StaffSession session, int centerId) => ProviderScope(
  overrides: [
    staffAuthProvider.overrideWith(() => _SignedIn(session)),
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
          name: 'Bacong Gym',
          barangayId: 4,
          status: 'active',
        ),
        EvacuationCenterLookup(
          id: 6,
          name: 'Tupas Barangay Hall',
          barangayId: 55,
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
    home: AddEvacueeFormPage(centerId: centerId, evacuationEventId: 7),
  ),
);

const _note =
    'This center is in Tupas. Add only people who are staying at this center.';

void main() {
  testWidgets('an official at another barangay\'s center sees the note', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_session('barangay_official', 4), 6));
    await tester.pumpAndSettle();
    expect(find.text(_note), findsOneWidget);
  });

  testWidgets('no note at the official\'s own barangay', (tester) async {
    await tester.pumpWidget(_app(_session('barangay_official', 4), 1));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Add only people who are staying'),
      findsNothing,
    );
  });

  testWidgets('no note for staff who see every barangay', (tester) async {
    await tester.pumpWidget(_app(_session('cswd_personnel', null), 6));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Add only people who are staying'),
      findsNothing,
    );
  });
}
