import 'family_member_draft.dart';

/// A `POST /families/register` request body, field-for-field —
/// verified against `RegisterFamilyRequest::rules()`. Every field
/// here is one the backend actually accepts; nothing is invented.
class FamilyRegistrationDraft {
  const FamilyRegistrationDraft({
    required this.evacuationEventId,
    required this.barangayId,
    this.homeAddress,
    required this.displacementType,
    this.evacuationCenterId,
    this.is4psBeneficiary = false,
    this.members = const [],
  });

  final int? evacuationEventId;
  final int? barangayId;

  /// The family's home address *inside* the barangay (e.g. "Purok 3,
  /// Sitio Mabuhay") — never an evacuation-center address. Optional
  /// on the backend (`nullable`, `max:255`); sent trimmed, and as
  /// `null` rather than `''` once trimmed empty (see [toJson]).
  final String? homeAddress;

  /// 'inside_center' | 'outside_center' — the only two values
  /// `RegisterFamilyRequest` accepts. Kept as the raw backend enum
  /// value internally; the form displays a localized label for it.
  final String? displacementType;

  /// Backend `required_if:displacement_type,inside_center`.
  final int? evacuationCenterId;

  /// Family-level flag — independent of each member's own
  /// `is_4ps_beneficiary`, confirmed as two separate fields on the
  /// backend.
  final bool is4psBeneficiary;

  final List<FamilyMemberDraft> members;

  bool get hasExactlyOneHead =>
      members.where((m) => m.isHeadOfFamily).length == 1;

  FamilyMemberDraft? get headOfFamily {
    for (final member in members) {
      if (member.isHeadOfFamily) return member;
    }
    return null;
  }

  /// True once every backend-required field is present — used to
  /// gate the submit button. Field-level validators still run in the
  /// form itself; this is a cheap pre-check, not a replacement for
  /// per-field validation or for the backend's own 422 response.
  bool get isSubmittable {
    if (evacuationEventId == null || barangayId == null) return false;
    if (displacementType == null) return false;
    if (displacementType == 'inside_center' && evacuationCenterId == null) {
      return false;
    }
    if (members.isEmpty || !hasExactlyOneHead) return false;
    for (final member in members) {
      if (member.firstName.trim().isEmpty || member.lastName.trim().isEmpty) {
        return false;
      }
      if (member.dateOfBirth.isEmpty) return false;
      if (member.isPwd &&
          (member.pwdType == null || member.pwdType!.trim().isEmpty)) {
        return false;
      }
    }
    return true;
  }

  FamilyRegistrationDraft copyWith({
    int? evacuationEventId,
    int? barangayId,
    String? homeAddress,
    String? displacementType,
    int? evacuationCenterId,
    bool clearEvacuationCenterId = false,
    bool? is4psBeneficiary,
    List<FamilyMemberDraft>? members,
  }) {
    return FamilyRegistrationDraft(
      evacuationEventId: evacuationEventId ?? this.evacuationEventId,
      barangayId: barangayId ?? this.barangayId,
      homeAddress: homeAddress ?? this.homeAddress,
      displacementType: displacementType ?? this.displacementType,
      evacuationCenterId: clearEvacuationCenterId
          ? null
          : (evacuationCenterId ?? this.evacuationCenterId),
      is4psBeneficiary: is4psBeneficiary ?? this.is4psBeneficiary,
      members: members ?? this.members,
    );
  }

  /// Trimmed, and `null` (never `''`) once trimmed empty — matches
  /// the backend's `nullable|string|max:255` rule, which treats an
  /// absent/blank address as "not provided" rather than a blank
  /// string value.
  String? get _normalizedHomeAddress {
    final trimmed = homeAddress?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  Map<String, dynamic> toJson() => {
    'evacuation_event_id': evacuationEventId,
    'barangay_id': barangayId,
    'home_address': _normalizedHomeAddress,
    'displacement_type': displacementType,
    if (evacuationCenterId != null) 'evacuation_center_id': evacuationCenterId,
    'is_4ps_beneficiary': is4psBeneficiary,
    'members': members.map((m) => m.toJson()).toList(),
  };

  factory FamilyRegistrationDraft.fromJson(Map<String, dynamic> json) {
    return FamilyRegistrationDraft(
      evacuationEventId: json['evacuation_event_id'] as int?,
      barangayId: json['barangay_id'] as int?,
      homeAddress: json['home_address'] as String?,
      displacementType: json['displacement_type'] as String?,
      evacuationCenterId: json['evacuation_center_id'] as int?,
      is4psBeneficiary: json['is_4ps_beneficiary'] as bool? ?? false,
      members: (json['members'] as List? ?? [])
          .map((m) => FamilyMemberDraft.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
