import 'package:elikas_mobile/features/box_relief/round_families_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('families by purok, with priority and the handout to void', () {
    final data = RoundFamilies.fromJson({
      'round': {'id': 1, 'round_number': 1},
      'barangay': {'id': 1, 'name': 'Abella'},
      'figures': {
        'need': 7,
        'received': 6,
        'given': 1,
        'left_to_give': 5,
        'short': 1,
      },
      'order': 'priority',
      'puroks': [
        {
          'purok': {'id': 7, 'name': 'Purok 1'},
          'given': 1,
          'families': [
            {
              'id': 548,
              'name': 'Fe Flor',
              'member_count': 2,
              'priority_tier': 1,
              'priority_label': 'Infant',
              'priority_order': 1,
              'given': false,
              'handout_id': null,
            },
            {
              'id': 547,
              'name': 'Elsa Erni',
              'member_count': 1,
              'priority_tier': 2,
              'priority_label': 'Pregnant / lactating',
              'priority_order': 2,
              'given': true,
              'handout_id': 3,
            },
          ],
        },
        {'purok': null, 'given': 0, 'families': []},
      ],
    });
    expect(data.figures.leftToGive, 5);
    expect(data.puroks.first.name, 'Purok 1');
    expect(data.puroks.last.name, isNull);
    final elsa = data.puroks.first.families[1];
    expect(elsa.given, isTrue);
    expect(elsa.handoutId, 3);
    expect(data.puroks.first.families.first.priorityLabel, 'Infant');
  });
}
