import 'package:elikas_mobile/core/error/failure.dart';
import 'package:elikas_mobile/core/error/result.dart';
import 'package:elikas_mobile/features/barangay_status/data/barangay_outlines.dart';
import 'package:elikas_mobile/features/barangay_status/domain/barangay_status.dart';
import 'package:elikas_mobile/features/barangay_status/presentation/barangay_status_providers.dart';
import 'package:elikas_mobile/features/barangay_status/presentation/resident_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../helpers/fake_staff_auth.dart';

/// "Your area": the barangay comes from the phone's location and the
/// bundled boundaries; there is nothing to choose.
const _square = BarangayOutline(
  psgcCode: '050508013',
  name: 'Binatagan',
  rings: [
    [
      LatLng(13.0, 123.0),
      LatLng(13.0, 123.1),
      LatLng(13.1, 123.1),
      LatLng(13.1, 123.0),
    ],
    // A hole in the middle (another barangay inside it).
    [
      LatLng(13.04, 123.04),
      LatLng(13.04, 123.06),
      LatLng(13.06, 123.06),
      LatLng(13.06, 123.04),
    ],
  ],
);

const _board = BarangayStatusBoard(
  eventName: 'Typhoon Pepito',
  eventStatus: 'active',
  barangays: [
    BarangayStatus(
      id: 13,
      name: 'Binatagan',
      psgcCode: '050508013',
      status: 'preemptive_evacuation',
      label: 'Preemptive evacuation',
    ),
  ],
);

Widget _card(Result<LatLng> position) => testApp(
  const Scaffold(body: SingleChildScrollView(child: YourAreaCard())),
  overrides: [
    residentPositionProvider.overrideWith((ref) async => position),
    barangayOutlinesProvider.overrideWith((ref) async => const [_square]),
    barangayStatusBoardProvider.overrideWith((ref) async => _board),
  ],
);

void main() {
  test('the barangay at a point: inside the outline, not in a hole', () {
    expect(
      barangayAt(const [_square], const LatLng(13.02, 123.02))?.name,
      'Binatagan',
    );
    expect(barangayAt(const [_square], const LatLng(13.05, 123.05)), isNull);
    expect(barangayAt(const [_square], const LatLng(13.5, 123.5)), isNull);
  });

  testWidgets('the area, its status in words and what to do', (tester) async {
    await tester.pumpWidget(_card(const Success(LatLng(13.02, 123.02))));
    await tester.pumpAndSettle();
    expect(find.text('Your area: Brgy. Binatagan'), findsOneWidget);
    expect(find.text('Preemptive evacuation'), findsOneWidget);
    expect(
      find.text('Preemptive evacuation: go to your evacuation center now.'),
      findsOneWidget,
    );
    expect(find.text('Typhoon Pepito'), findsOneWidget);
  });

  testWidgets('no location, or outside Ligao: no card, nothing to choose', (
    tester,
  ) async {
    await tester.pumpWidget(_card(const Failed(LocationFailure('off', false))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your area'), findsNothing);

    await tester.pumpWidget(_card(const Success(LatLng(14.6, 121.0))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your area'), findsNothing);
  });
}
