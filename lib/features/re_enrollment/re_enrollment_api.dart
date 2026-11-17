import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/network/staff_api_client.dart';
import '../../core/network/staff_api_error_mapper.dart';

/// A closed past event with re-enrollable families of the barangay.
class PastEvent {
  const PastEvent({
    required this.id,
    required this.name,
    required this.familyCount,
  });

  final int id;
  final String name;
  final int familyCount;
}

class ReturningMember {
  const ReturningMember({
    required this.id,
    required this.fullName,
    required this.sex,
    required this.needsAgeBracket,
    required this.wasPregnant,
    required this.wasLactating,
    required this.checkedIn,
    this.ageBracket,
    this.age,
  });

  final int id;
  final String fullName;
  final String? sex;

  /// No birthdate: the age group must be asked and sent.
  final bool needsAgeBracket;

  /// True in the past event; never carried over, asked again.
  final bool wasPregnant;
  final bool wasLactating;

  /// Already checked in somewhere in the current event: cannot be ticked.
  final bool checkedIn;
  final String? ageBracket;
  final int? age;

  bool get isFemale => sex == 'female';
}

class ReturningFamily {
  const ReturningFamily({
    required this.id,
    required this.name,
    required this.members,
    required this.unnamedMemberCount,
    this.purokName,
    this.lastCenterName,
    this.reEnrolledFamilyId,
  });

  final int id;
  final String name;
  final String? purokName;
  final String? lastCenterName;

  /// Already in the current event: cannot be re-enrolled again.
  final int? reEnrolledFamilyId;
  final int unnamedMemberCount;
  final List<ReturningMember> members;
}

class ReturningFamiliesResult {
  const ReturningFamiliesResult({
    required this.pastEvents,
    required this.families,
  });

  final List<PastEvent> pastEvents;
  final List<ReturningFamily> families;
}

/// One ticked member, with what had to be asked again.
class ReEnrollMember {
  const ReEnrollMember({
    required this.evacueeId,
    this.ageBracket,
    this.isPregnant,
    this.isLactating,
  });

  final int evacueeId;
  final String? ageBracket;
  final bool? isPregnant;
  final bool? isLactating;

  Map<String, dynamic> toJson() => {
    'evacuee_id': evacueeId,
    if (ageBracket != null) 'age_bracket': ageBracket,
    if (isPregnant != null) 'is_pregnant': isPregnant,
    if (isLactating != null) 'is_lactating': isLactating,
  };
}

/// A family already in this event that may be the same one (409).
class PossibleDuplicate {
  const PossibleDuplicate({
    required this.familyId,
    required this.name,
    required this.memberCount,
    this.centerName,
  });

  final int familyId;
  final String name;
  final int memberCount;
  final String? centerName;
}

sealed class ReEnrollOutcome {
  const ReEnrollOutcome();
}

class ReEnrolled extends ReEnrollOutcome {
  const ReEnrolled({required this.membersAdded, required this.membersLinked});

  final int membersAdded;
  final int membersLinked;
}

class NeedsDuplicateDecision extends ReEnrollOutcome {
  const NeedsDuplicateDecision(this.candidates);

  final List<PossibleDuplicate> candidates;
}

class ReEnrollRefused extends ReEnrollOutcome {
  const ReEnrollRefused(this.message);

  final String message;
}

/// Backend step 10: `GET .../returning-families` and `POST .../re-enroll`.
/// Online only: it searches the server's past events.
class ReEnrollmentApi {
  ReEnrollmentApi(this._api);

  final StaffApiClient _api;

  Future<ReturningFamiliesResult> list({
    required int centerId,
    required int eventId,
    int? sourceEventId,
    String? search,
  }) async {
    final response = await _api.get(
      '/evacuation-centers/$centerId/returning-families',
      queryParameters: {
        'evacuation_event_id': eventId,
        'source_event_id': ?sourceEventId,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data =
        (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return ReturningFamiliesResult(
      pastEvents: [
        for (final e in data['past_events'] as List? ?? const [])
          PastEvent(
            id: (e as Map<String, dynamic>)['id'] as int,
            name: e['name'] as String,
            familyCount: (e['family_count'] as num?)?.toInt() ?? 0,
          ),
      ],
      families: [
        for (final f in data['families'] as List? ?? const [])
          _family(f as Map<String, dynamic>),
      ],
    );
  }

  static ReturningFamily _family(Map<String, dynamic> f) => ReturningFamily(
    id: f['id'] as int,
    name: f['name'] as String? ?? '',
    purokName: (f['purok'] as Map<String, dynamic>?)?['name'] as String?,
    lastCenterName:
        (f['last_center'] as Map<String, dynamic>?)?['name'] as String?,
    reEnrolledFamilyId: f['re_enrolled_family_id'] as int?,
    unnamedMemberCount: (f['unnamed_member_count'] as num?)?.toInt() ?? 0,
    members: [
      for (final m in f['members'] as List? ?? const [])
        () {
          final member = m as Map<String, dynamic>;
          return ReturningMember(
            id: member['id'] as int,
            fullName: member['full_name'] as String? ?? '',
            sex: member['sex'] as String?,
            age: (member['age'] as num?)?.toInt(),
            ageBracket: member['age_bracket'] as String?,
            needsAgeBracket: member['needs_age_bracket'] == true,
            wasPregnant: member['was_pregnant'] == true,
            wasLactating: member['was_lactating'] == true,
            checkedIn: member['checked_in'] == true,
          );
        }(),
    ],
  );

  /// [duplicateDecision] is `link` (with [linkFamilyId]) or `different`.
  Future<ReEnrollOutcome> reEnroll({
    required int centerId,
    required int eventId,
    required int sourceFamilyId,
    required List<ReEnrollMember> members,
    String? duplicateDecision,
    int? linkFamilyId,
    String? clientRef,
  }) async {
    try {
      final response = await _api.post(
        '/evacuation-centers/$centerId/re-enroll',
        data: {
          'evacuation_event_id': eventId,
          'source_family_id': sourceFamilyId,
          'members': [for (final m in members) m.toJson()],
          'duplicate_decision': duplicateDecision,
          'link_family_id': linkFamilyId,
          'client_ref': ?clientRef,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final body = data['data'] as Map<String, dynamic>? ?? data;
      return ReEnrolled(
        membersAdded: (body['members_added'] as num?)?.toInt() ?? 0,
        membersLinked: (body['members_linked'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      if (e.response?.statusCode == 409 && body is Map<String, dynamic>) {
        final data = body['data'] as Map<String, dynamic>? ?? const {};
        return NeedsDuplicateDecision([
          for (final d in data['possible_duplicates'] as List? ?? const [])
            PossibleDuplicate(
              familyId: (d as Map<String, dynamic>)['family_id'] as int,
              name: d['name'] as String? ?? '',
              memberCount: (d['member_count'] as num?)?.toInt() ?? 0,
              centerName:
                  (d['evacuation_center'] as Map<String, dynamic>?)?['name']
                      as String?,
            ),
        ]);
      }
      final failure = mapStaffDioError(e);
      return ReEnrollRefused(
        failure is ValidationFailure && failure.fieldErrors.isNotEmpty
            ? failure.fieldErrors.values.expand((m) => m).join(' ')
            : failure.message,
      );
    }
  }
}

final reEnrollmentApiProvider = Provider<ReEnrollmentApi>(
  (ref) => ReEnrollmentApi(ref.watch(staffApiClientProvider)),
);
