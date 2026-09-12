/// One `members[]` entry of a `POST /families/register` request —
/// field set and names verified directly against
/// `RegisterFamilyRequest::rules()`. No field exists here that the
/// backend doesn't also accept.
class FamilyMemberDraft {
  const FamilyMemberDraft({
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.suffix,
    required this.sex,
    required this.dateOfBirth,
    this.civilStatus,
    this.contactNumber,
    this.isPwd = false,
    this.pwdType,
    this.isPregnant = false,
    this.isLactating = false,
    this.isSoloParent = false,
    this.isIndigenousPerson = false,
    this.is4psBeneficiary = false,
    this.isHeadOfFamily = false,
  });

  final String firstName;
  final String? middleName;
  final String lastName;
  final String? suffix;

  /// 'male' | 'female' — the only two values `RegisterFamilyRequest`
  /// accepts.
  final String sex;

  /// ISO `yyyy-MM-dd`, must not be in the future
  /// (`before_or_equal:today` on the backend).
  final String dateOfBirth;

  /// 'single' | 'married' | 'widowed' | 'separated' | 'divorced', or
  /// null (nullable on the backend).
  final String? civilStatus;
  final String? contactNumber;

  final bool isPwd;

  /// Backend `required_if:members.*.is_pwd,true`.
  final String? pwdType;

  final bool isPregnant;
  final bool isLactating;
  final bool isSoloParent;
  final bool isIndigenousPerson;
  final bool is4psBeneficiary;
  final bool isHeadOfFamily;

  FamilyMemberDraft copyWith({
    String? firstName,
    String? middleName,
    bool clearMiddleName = false,
    String? lastName,
    String? suffix,
    bool clearSuffix = false,
    String? sex,
    String? dateOfBirth,
    String? civilStatus,
    bool clearCivilStatus = false,
    String? contactNumber,
    bool clearContactNumber = false,
    bool? isPwd,
    String? pwdType,
    bool clearPwdType = false,
    bool? isPregnant,
    bool? isLactating,
    bool? isSoloParent,
    bool? isIndigenousPerson,
    bool? is4psBeneficiary,
    bool? isHeadOfFamily,
  }) {
    return FamilyMemberDraft(
      firstName: firstName ?? this.firstName,
      middleName: clearMiddleName ? null : (middleName ?? this.middleName),
      lastName: lastName ?? this.lastName,
      suffix: clearSuffix ? null : (suffix ?? this.suffix),
      sex: sex ?? this.sex,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      civilStatus: clearCivilStatus ? null : (civilStatus ?? this.civilStatus),
      contactNumber: clearContactNumber
          ? null
          : (contactNumber ?? this.contactNumber),
      isPwd: isPwd ?? this.isPwd,
      pwdType: clearPwdType ? null : (pwdType ?? this.pwdType),
      isPregnant: isPregnant ?? this.isPregnant,
      isLactating: isLactating ?? this.isLactating,
      isSoloParent: isSoloParent ?? this.isSoloParent,
      isIndigenousPerson: isIndigenousPerson ?? this.isIndigenousPerson,
      is4psBeneficiary: is4psBeneficiary ?? this.is4psBeneficiary,
      isHeadOfFamily: isHeadOfFamily ?? this.isHeadOfFamily,
    );
  }

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'middle_name': middleName,
    'last_name': lastName,
    'suffix': suffix,
    'sex': sex,
    'date_of_birth': dateOfBirth,
    'civil_status': civilStatus,
    'contact_number': contactNumber,
    'is_pwd': isPwd,
    'pwd_type': pwdType,
    'is_pregnant': isPregnant,
    'is_lactating': isLactating,
    'is_solo_parent': isSoloParent,
    'is_indigenous_person': isIndigenousPerson,
    'is_4ps_beneficiary': is4psBeneficiary,
    'is_head_of_family': isHeadOfFamily,
  };

  factory FamilyMemberDraft.fromJson(Map<String, dynamic> json) {
    return FamilyMemberDraft(
      firstName: json['first_name'] as String,
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String,
      suffix: json['suffix'] as String?,
      sex: json['sex'] as String,
      dateOfBirth: json['date_of_birth'] as String,
      civilStatus: json['civil_status'] as String?,
      contactNumber: json['contact_number'] as String?,
      isPwd: json['is_pwd'] as bool? ?? false,
      pwdType: json['pwd_type'] as String?,
      isPregnant: json['is_pregnant'] as bool? ?? false,
      isLactating: json['is_lactating'] as bool? ?? false,
      isSoloParent: json['is_solo_parent'] as bool? ?? false,
      isIndigenousPerson: json['is_indigenous_person'] as bool? ?? false,
      is4psBeneficiary: json['is_4ps_beneficiary'] as bool? ?? false,
      isHeadOfFamily: json['is_head_of_family'] as bool? ?? false,
    );
  }

  String get fullName => [
    firstName,
    if (middleName != null && middleName!.isNotEmpty) middleName,
    lastName,
    if (suffix != null && suffix!.isNotEmpty) suffix,
  ].join(' ');
}
