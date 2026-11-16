import 'package:elikas_mobile/features/alerts/data/models/alert_model.dart';
import 'package:elikas_mobile/features/alerts/presentation/providers/alerts_summary_provider.dart';
import 'package:elikas_mobile/features/barangay_status/domain/barangay_status.dart';
import 'package:elikas_mobile/features/barangay_status/presentation/barangay_status_providers.dart';
import 'package:elikas_mobile/features/barangay_status/presentation/drill_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_auth.dart';

Map<String, dynamic> _alert({bool drill = false}) => {
  'id': 7,
  'title': 'Evacuate now',
  'message': 'Go to the nearest center.',
  'alert_type': 'evacuation',
  'status': 'sent',
  'severity': 'mandatory',
  'is_drill': drill,
};

Widget _notice({required bool boardDrill, bool alertDrill = false}) => testApp(
  const Scaffold(body: DrillNotice()),
  overrides: [
    barangayStatusBoardProvider.overrideWith(
      (ref) async =>
          BarangayStatusBoard(barangays: const [], isDrill: boardDrill),
    ),
    alertsSummaryProvider.overrideWith(
      (ref) async => (
        latest: AlertModel.fromJson(_alert(drill: alertDrill)).toEntity(),
        count: 1,
      ),
    ),
  ],
);

void main() {
  test('alerts read is_drill', () {
    expect(AlertModel.fromJson(_alert(drill: true)).toEntity().isDrill, isTrue);
    expect(
      AlertModel.fromJson(_alert()..remove('is_drill')).toEntity().isDrill,
      isFalse,
    );
  });

  for (final (name, board, alert, shown) in [
    ('a drill barangay board', true, false, true),
    ('a drill alert', false, true, true),
    ('no drill', false, false, false),
  ]) {
    testWidgets('drill notice: $name', (tester) async {
      await tester.pumpWidget(_notice(boardDrill: board, alertDrill: alert));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('DRILL - This is a simulation'),
        shown ? findsOneWidget : findsNothing,
      );
    });
  }
}
