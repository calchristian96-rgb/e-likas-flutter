import 'package:elikas_mobile/features/family_registration/data/models/lookup_evacuation_event_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('is_demo is read from GET /evacuation-events and defaults to false', () {
    final demo = LookupEvacuationEventModel.fromJson({
      'id': 30,
      'name': 'DEMO - Typhoon Drill',
      'status': 'active',
      'is_demo': true,
    });
    final real = LookupEvacuationEventModel.fromJson({
      'id': 21,
      'name': 'Typhoon X',
      'status': 'active',
    });
    expect(demo.isDemo, isTrue);
    expect(real.isDemo, isFalse);
  });
}
