/// One family as `GET /families/{id}` returns it right now — fetched
/// live for the family detail sheet's member list and Check out, and
/// deliberately **never cached**: it carries each member's id and
/// check-in state, which `CachedFamilyModel` leaves out on purpose.
class FamilyRecord {
  const FamilyRecord({
    required this.id,
    required this.members,
    required this.hasHeadLinked,
    required this.isLegacyBulkEntry,
    this.headSex,
    this.isChildHeaded,
  });

  final int id;
  final List<FamilyRecordMember> members;

  /// Whether a member is linked as head — when not, the sheet shows the
  /// same "Head not yet linked" reminder as the web family page, with
  /// the answers the board's counts are using ([headSex],
  /// [isChildHeaded]; null = not yet known).
  final bool hasHeadLinked;
  final bool isLegacyBulkEntry;
  final String? headSex;
  final bool? isChildHeaded;
}

class FamilyRecordMember {
  const FamilyRecordMember({
    required this.id,
    required this.fullName,
    required this.isPlaceholder,
    required this.isHead,
    this.openStayCenterName,
    this.hasOpenStay = false,
  });

  /// The backend's `evacuees.id` — what `POST /evacuees/{id}/check-out`
  /// takes.
  final int id;
  final String fullName;

  /// Added by headcount (Add Evacuee) and still missing name/sex/
  /// birthdate — shown as "Member N — details pending", like the web.
  final bool isPlaceholder;
  final bool isHead;

  /// True while this member's evacuation record is still open (no
  /// `date_out`) — the only time Check out is offered.
  final bool hasOpenStay;

  /// The open record's center, when it has one.
  final String? openStayCenterName;
}

/// `POST /evacuees/{id}/check-out`'s two accepted `status` values —
/// the same two Quick Departure uses.
enum CheckOutReason {
  returnedHome,
  transferred;

  String get wireValue => switch (this) {
    CheckOutReason.returnedHome => 'returned_home',
    CheckOutReason.transferred => 'transferred',
  };
}
