import 'package:elikas_mobile/features/count_submissions/final_count_card.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _computed({String? status, int families = 43}) => {
  'evacuation_event': {'id': 21, 'name': 'Typhoon', 'status': 'active'},
  'barangay': {'id': 13, 'name': 'Binatagan'},
  'computed': {
    'families': families,
    'families_inside_ec': 31,
    'families_outside_ec': 10,
    'persons': 164,
    'persons_inside_ec': 119,
    'persons_outside_ec': 45,
  },
  'current_submission': status == null
      ? null
      : {
          'id': 12,
          'version': 2,
          'status': status,
          'families': 43,
          'families_inside_ec': 31,
          'families_outside_ec': 10,
          'persons': 164,
          'persons_inside_ec': 119,
          'persons_outside_ec': 45,
          'review_note': status == 'returned' ? 'Recount Purok 3' : null,
        },
  'validated_need': status == 'validated'
      ? {'families': 41, 'persons': 158}
      : null,
  'has_official_account': true,
};

void main() {
  test('first submission; families with no stay recorded are shown apart', () {
    final c = ComputedCount.fromJson(_computed());
    expect(c.canSubmit, isTrue);
    expect(c.computed.familiesNoStay, 2);
  });

  test('a waiting submission with the same numbers cannot be sent again', () {
    expect(
      ComputedCount.fromJson(_computed(status: 'pending')).canSubmit,
      isFalse,
    );
    final changed = ComputedCount.fromJson(
      _computed(status: 'pending', families: 44),
    );
    expect(changed.changedSinceSubmission, isTrue);
    expect(changed.canSubmit, isTrue);
  });

  test('after a return or a validation, an updated count may be sent', () {
    final returned = ComputedCount.fromJson(_computed(status: 'returned'));
    expect(returned.canSubmit, isTrue);
    expect(returned.reviewNote, 'Recount Purok 3');
    final validated = ComputedCount.fromJson(_computed(status: 'validated'));
    expect(validated.validatedFamilies, 41);
  });

  test('validated and nothing new: Submit stays off until late entries', () {
    final validated = ComputedCount.fromJson(_computed(status: 'validated'));
    expect(validated.nothingNewSinceValidated, isTrue);
    expect(validated.canSubmit, isFalse);
    final late = ComputedCount.fromJson({
      ..._computed(status: 'validated'),
      'late_entries': {
        'since': '2026-11-17T06:00:00+00:00',
        'submission_id': 12,
        'submission_status': 'validated',
        'families': 3,
        'persons': 11,
        'removed_families': 0,
        'removed_persons': 0,
        'total': 3,
      },
    });
    expect(late.nothingNewSinceValidated, isFalse);
    expect(late.canSubmit, isTrue);
  });

  test('a count CSWD submitted on behalf carries its note', () {
    final data = _computed(status: 'validated');
    (data['current_submission'] as Map<String, dynamic>)['note'] =
        'Submitted by CSWD on behalf of Binatagan. Reason: No answer for two days.';
    final c = ComputedCount.fromJson(data);
    expect(c.submittedOnBehalf, isTrue);
    expect(c.submissionNote, contains('Reason: No answer for two days.'));
  });
}
