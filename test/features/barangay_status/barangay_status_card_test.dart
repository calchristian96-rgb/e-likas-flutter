import 'package:elikas_mobile/features/barangay_status/domain/barangay_status.dart';
import 'package:elikas_mobile/features/barangay_status/presentation/barangay_status_card.dart';
import 'package:elikas_mobile/features/barangay_status/presentation/barangay_status_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_auth.dart';

class _Chosen extends ResidentBarangayNotifier {
  _Chosen(this.value);
  final ResidentBarangay? value;
  @override
  ResidentBarangay? build() => value;
}

const _board = BarangayStatusBoard(
  eventName: 'Typhoon X',
  eventStatus: 'active',
  barangays: [
    BarangayStatus(
      id: 13,
      name: 'Binatagan',
      status: 'flooding_reported',
      label: 'Flooding reported',
    ),
  ],
);

Widget _card(ResidentBarangay? chosen) => testApp(
  const Scaffold(body: BarangayStatusCard()),
  overrides: [
    residentBarangayProvider.overrideWith(() => _Chosen(chosen)),
    barangayStatusBoardProvider.overrideWith((ref) async => _board),
  ],
);

void main() {
  testWidgets('shows the own barangay status as a word', (tester) async {
    await tester.pumpWidget(
      _card(const ResidentBarangay(id: 13, name: 'Binatagan')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Brgy. Binatagan'), findsOneWidget);
    expect(find.text('Flooding reported'), findsOneWidget);
    expect(find.text('Typhoon X'), findsOneWidget);
  });

  testWidgets('asks for the barangay when none is chosen', (tester) async {
    await tester.pumpWidget(_card(null));
    await tester.pumpAndSettle();
    expect(find.text('Choose your barangay'), findsOneWidget);
  });
}
