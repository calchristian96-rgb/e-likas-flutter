import 'package:elikas_mobile/features/re_enrollment/re_enrollment_api.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';

void main() {
  const path = 'POST /evacuation-centers/42/re-enroll';

  test(
    'a possible duplicate (409) asks the user, with the candidates',
    () async {
      final api = FakeStaffApi()
        ..answer(path, (
          409,
          {
            'success': false,
            'message':
                'A family that may be the same one is already in this event.',
            'errors': null,
            'data': {
              'possible_duplicates': [
                {
                  'family_id': 505,
                  'name': 'Juan Dela Cruz',
                  'member_count': 1,
                  'evacuation_center': {
                    'id': 42,
                    'name': 'Abella ALS Building',
                  },
                  'matched_on': ['name'],
                },
              ],
            },
          },
        ));
      final outcome = await ReEnrollmentApi(api).reEnroll(
        centerId: 42,
        eventId: 24,
        sourceFamilyId: 502,
        members: const [ReEnrollMember(evacueeId: 1804, isPregnant: false)],
      );
      expect(outcome, isA<NeedsDuplicateDecision>());
      final c = (outcome as NeedsDuplicateDecision).candidates.single;
      expect(c.familyId, 505);
      expect(c.centerName, 'Abella ALS Building');
      expect(api.bodies.single, {
        'evacuation_event_id': 24,
        'source_family_id': 502,
        'members': [
          {'evacuee_id': 1804, 'is_pregnant': false},
        ],
        'duplicate_decision': null,
        'link_family_id': null,
      });
    },
  );

  test('a link decision is sent; the answer counts who was added', () async {
    final api = FakeStaffApi()
      ..answer(path, (
        201,
        {
          'success': true,
          'data': {'members_added': 1, 'members_linked': 1},
        },
      ));
    final outcome = await ReEnrollmentApi(api).reEnroll(
      centerId: 42,
      eventId: 24,
      sourceFamilyId: 502,
      members: const [
        ReEnrollMember(evacueeId: 1804),
        ReEnrollMember(evacueeId: 1810, ageBracket: 'adult'),
      ],
      duplicateDecision: 'link',
      linkFamilyId: 505,
    );
    expect(outcome, isA<ReEnrolled>());
    expect((outcome as ReEnrolled).membersAdded + outcome.membersLinked, 2);
    final body = api.bodies.single as Map<String, dynamic>;
    expect(body['duplicate_decision'], 'link');
    expect((body['members'] as List)[1], {
      'evacuee_id': 1810,
      'age_bracket': 'adult',
    });
  });
}
