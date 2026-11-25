/// A sent family as the server has it now (`GET /families/{id}`,
/// FamilyResource with its members), for the edit screen.
class SentFamily {
  const SentFamily({
    required this.id,
    required this.members,
    this.name,
    this.headId,
    this.headName,
    this.barangayName,
    this.isSingleHeaded,
    this.isChildHeaded,
    this.headSex,
  });

  factory SentFamily.fromJson(Map<String, dynamic> j) {
    final head = j['head_of_family'];
    final barangay = j['barangay'];
    return SentFamily(
      id: j['id'] as int,
      name: j['name'] as String?,
      headId: head is Map ? head['id'] as int? : null,
      headName: head is Map ? head['full_name'] as String? : null,
      barangayName: barangay is Map ? barangay['name'] as String? : null,
      isSingleHeaded: j['is_single_headed'] as bool?,
      isChildHeaded: j['is_child_headed'] as bool?,
      headSex: j['head_sex'] as String?,
      members: [
        for (final m in j['members'] as List? ?? const [])
          SentMember.fromJson(m as Map<String, dynamic>),
      ],
    );
  }

  final int id;

  /// The household's name when the head is not a listed member.
  final String? name;
  final int? headId;
  final String? headName;
  final String? barangayName;

  /// null = not yet known.
  final bool? isSingleHeaded;
  final bool? isChildHeaded;

  /// The head's sex when the head is not a listed member.
  final String? headSex;
  final List<SentMember> members;

  String get title => headName ?? name ?? '';
}

/// One member as the server has it (EvacueeResource).
class SentMember {
  const SentMember({
    required this.id,
    this.fullName,
    this.firstName,
    this.middleName,
    this.lastName,
    this.suffix,
    this.sex,
    this.dateOfBirth,
    this.ageBracket,
    this.civilStatus,
    this.contactNumber,
    this.isPwd = false,
    this.pwdType,
    this.isPregnant = false,
    this.isLactating = false,
    this.isSoloParent = false,
    this.isIndigenousPerson = false,
    this.is4psBeneficiary = false,
  });

  factory SentMember.fromJson(Map<String, dynamic> j) {
    final s = j['sectoral'] is Map ? j['sectoral'] as Map : const {};
    bool flag(String key) => s[key] == true || j[key] == true;
    return SentMember(
      id: j['id'] as int,
      fullName: _text(j['full_name']),
      firstName: _text(j['first_name']),
      middleName: _text(j['middle_name']),
      lastName: _text(j['last_name']),
      suffix: _text(j['suffix']),
      sex: _text(j['sex']),
      dateOfBirth: _text(j['date_of_birth']),
      ageBracket: _text(j['age_bracket']),
      civilStatus: _text(j['civil_status']),
      contactNumber: _text(j['contact_number']),
      isPwd: flag('is_pwd'),
      pwdType: _text(s['pwd_type'] ?? j['pwd_type']),
      isPregnant: flag('is_pregnant'),
      isLactating: flag('is_lactating'),
      isSoloParent: flag('is_solo_parent'),
      isIndigenousPerson: flag('is_indigenous_person'),
      is4psBeneficiary: flag('is_4ps_beneficiary'),
    );
  }

  final int id;
  final String? fullName;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? suffix;

  /// male | female | null (an EC Board person may have none yet).
  final String? sex;

  /// `YYYY-MM-DD`.
  final String? dateOfBirth;
  final String? ageBracket;
  final String? civilStatus;
  final String? contactNumber;
  final bool isPwd;
  final String? pwdType;
  final bool isPregnant;
  final bool isLactating;
  final bool isSoloParent;
  final bool isIndigenousPerson;
  final bool is4psBeneficiary;

  static String? _text(Object? v) =>
      v is String && v.trim().isNotEmpty ? v : null;
}
