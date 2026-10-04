/// One family with someone checked in at a center for an event right now
/// -- a row of `GET /evacuation-centers/{id}/families`, the list the
/// web dashboard's Add Evacuee "Already here" offers.
///
/// A family of another barangay comes from the server without a name
/// ([isGeneric]): only its number, home barangay, how many of its people
/// are here and whether a head is linked -- shown as "Family #N ·
/// (its home barangay) · X here". The family's own barangay officials, CSWDO and
/// administrators get the named record.
class FamilyHere {
  const FamilyHere({
    required this.id,
    required this.isGeneric,
    required this.memberCount,
    required this.headLinked,
    this.name,
    this.barangayName,
    this.hereCount,
  });

  factory FamilyHere.fromJson(Map<String, dynamic> json) {
    final isGeneric = json['is_generic'] == true;
    final head = json['head_of_family'] as Map<String, dynamic>?;
    final name = (json['name'] as String?)?.trim();
    final barangay = json['barangay'] as Map<String, dynamic>?;
    return FamilyHere(
      id: json['id'] as int,
      isGeneric: isGeneric,
      name: isGeneric
          ? null
          : (name != null && name.isNotEmpty
                ? name
                : head?['full_name'] as String?),
      barangayName: barangay?['name'] as String?,
      hereCount: (json['here_count'] as num?)?.toInt(),
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      // Another barangay's family has no head_of_family: the server says
      // whether one is linked instead.
      headLinked: isGeneric
          ? json['has_head_linked'] == true
          : head != null,
    );
  }

  final int id;
  final bool isGeneric;

  /// The family's name, else its head's -- null for [isGeneric], or a
  /// family with neither on record yet.
  final String? name;
  final String? barangayName;

  /// How many of its people are here -- given for [isGeneric] only.
  final int? hereCount;
  final int memberCount;
  final bool headLinked;
}
