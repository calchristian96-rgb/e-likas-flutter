import 'package:elikas_mobile/features/barangay_status/staff/barangay_page.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shaped like GET /gis/situation in backend docs/map-api.md.
Map<String, dynamic> _situation({bool mayUpdate = true, bool open = true}) => {
  'evacuation_event': {
    'id': 18,
    'name': 'Typhoon X',
    'status': 'active',
    'is_demo': false,
  },
  'open': open,
  'statuses': [
    {
      'key': 'normal',
      'label': 'Normal',
      'rank': 0,
      'evacuation_order': false,
      'may_set': true,
    },
    {
      'key': 'watch',
      'label': 'Watch',
      'rank': 1,
      'evacuation_order': false,
      'may_set': true,
    },
    {
      'key': 'flooding_reported',
      'label': 'Flooding reported',
      'rank': 2,
      'evacuation_order': false,
      'may_set': true,
    },
    {
      'key': 'preemptive_evacuation',
      'label': 'Preemptive evacuation',
      'rank': 3,
      'evacuation_order': true,
      'may_set': false,
    },
    {
      'key': 'forced_evacuation',
      'label': 'Forced evacuation',
      'rank': 4,
      'evacuation_order': true,
      'may_set': false,
    },
  ],
  'barangays': [
    {
      'barangay': {'id': 1, 'name': 'Abella'},
      'status': 'normal',
      'label': 'Normal',
      'may_update': false,
    },
    {
      'barangay': {'id': 13, 'name': 'Binatagan', 'psgc_code': '050508013'},
      'status': 'flooding_reported',
      'label': 'Flooding reported',
      'rank': 2,
      'note': 'Knee-deep at Purok 3.',
      'set_by': {'id': 52, 'name': 'Juan Dela Cruz'},
      'set_at': '2026-11-15T06:20:00+00:00',
      'may_update': mayUpdate,
    },
  ],
};

void main() {
  test("the official's own row, and only the statuses they may set", () {
    final s = OwnSituation.fromJson(_situation(), 13)!;
    expect(s.eventId, 18);
    expect(s.label, 'Flooding reported');
    expect(s.note, 'Knee-deep at Purok 3.');
    expect(s.setBy, 'Juan Dela Cruz');
    expect(s.mayUpdate, isTrue);
    expect(s.options.where((o) => o.maySet).map((o) => o.key), [
      'normal',
      'watch',
      'flooding_reported',
    ]);
  });

  test('under a CSWD order the row cannot be changed', () {
    expect(
      OwnSituation.fromJson(_situation(mayUpdate: false), 13)!.mayUpdate,
      isFalse,
    );
    expect(OwnSituation.fromJson(_situation(), 99), isNull);
  });
}
