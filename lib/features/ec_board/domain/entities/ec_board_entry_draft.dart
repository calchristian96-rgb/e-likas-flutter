import 'age_bracket.dart';
import 'per_person_sectoral_flag.dart';

/// 'existing' | 'new' — the only two `household_mode` values
/// `POST /evacuation-centers/{id}/evacuees` accepts.
enum HouseholdMode {
  existing,
  new_;

  String get wireValue => switch (this) {
    HouseholdMode.existing => 'existing',
    HouseholdMode.new_ => 'new',
  };

  static HouseholdMode fromWire(String value) => switch (value) {
    'new' => HouseholdMode.new_,
    _ => HouseholdMode.existing,
  };
}

/// The confirmed result of a successful `POST
/// /evacuation-centers/{id}/evacuees` — both the new evacuee's own id
/// and the household's real `families.id`, always present in the
/// response regardless of [HouseholdMode] (an "existing" submission
/// just echoes back the family it was already given). The family id
/// matters specifically for [HouseholdMode.new_]: `StaffSyncService`
/// uses it to promote any *other* still-pending EC Board entry that
/// referenced this one's own [PendingEcBoardEntrySummary.localId] as
/// its [EcBoardEntryDraft.existingFamilyLocalId] — see
/// `EcBoardRepository.promoteHouseholdReference`'s doc comment for why
/// that's the same mechanism a pending family registration's own
/// promotion already uses, just keyed by an EC Board entry's local id
/// instead of a `PendingFamilyRegistrations` one.
class EcBoardSubmitResult {
  const EcBoardSubmitResult({required this.evacueeId, required this.familyId});

  final int evacueeId;
  final int familyId;
}

/// A single Add Evacuee entry — one person's EC Information Board
/// intake record. Deliberately far smaller than
/// `FamilyRegistrationDraft`: this is a fast, single-evacuee counting
/// tool (bracket + sex + which household, plus the household's head
/// answers when it's new), not a full registration.
///
/// The household reference is split into two nullable ids rather than
/// one, to correctly represent "existing household" pointing at a
/// family that itself might not be synced to the backend yet:
/// [existingFamilyRemoteId] is a real, already-confirmed
/// `families.id` (from an already-synced family); [existingFamilyLocalId]
/// is this device's own still-`pending` `PendingFamilyRegistrations
/// .localId` for a household chosen before its own registration
/// synced. Exactly one of the two is ever set for
/// [HouseholdMode.existing] — see `EcBoardSyncPromotion` for how a
/// local reference gets promoted to a remote id once that family
/// registration itself syncs successfully.
class EcBoardEntryDraft {
  const EcBoardEntryDraft({
    required this.evacuationCenterId,
    required this.evacuationEventId,
    required this.sex,
    required this.ageBracket,
    required this.householdMode,
    this.existingFamilyRemoteId,
    this.existingFamilyLocalId,
    this.newHouseholdHeadName,
    this.newHouseholdBarangayId,
    this.sectoralFlags = const {},
    this.headIsSelf = false,
    this.isSingleHeaded,
    this.headIsMinor,
    this.headSex,
  });

  final int evacuationCenterId;
  final int? evacuationEventId;

  /// 'male' | 'female' — the only two values the backend accepts.
  final String? sex;

  final AgeBracket? ageBracket;
  final HouseholdMode householdMode;

  final int? existingFamilyRemoteId;
  final String? existingFamilyLocalId;

  final String? newHouseholdHeadName;
  final int? newHouseholdBarangayId;

  /// The optional sectoral flags ticked for this one person. Anything
  /// not in the set is "not recorded", not "no" — see
  /// [PerPersonSectoralFlag]. Never required for [isSubmittable].
  final Set<PerPersonSectoralFlag> sectoralFlags;

  /// This person IS the household head — for a new household (the
  /// form's default there), or for an existing one that has no head
  /// linked yet (the real head arriving later; never offered, and never
  /// honoured by the server, for a household that already has one).
  /// Their own sex and age group then answer "head's sex" and "is the
  /// head a minor?", so [headSex]/[headIsMinor] aren't asked.
  final bool headIsSelf;

  /// New household only: "Only one household head?" — null = not yet
  /// known, never a guessed "no" (same for [headIsMinor]/[headSex]).
  final bool? isSingleHeaded;

  /// New household with someone else as head only.
  final bool? headIsMinor;

  /// New household with someone else as head only: 'male' | 'female'.
  final String? headSex;

  bool get _isNew => householdMode == HouseholdMode.new_;

  /// The new household's head's sex by the server's own rule
  /// (`Family::headSex()`): this person's when they're the head,
  /// otherwise the [headSex] answer. Null for an existing household —
  /// its answers were given when it was created.
  String? get newHouseholdHeadSex =>
      !_isNew ? null : (headIsSelf ? sex : headSex);

  /// `Family::isChildHeaded()` for the household this creates — only
  /// true when known to be (null/unknown never counts).
  bool get createsChildHeadedHousehold =>
      _isNew && (headIsSelf ? ageBracket?.isMinor : headIsMinor) == true;

  /// `Family::isSingleHeaded()` for the household this creates.
  bool get createsSingleHeadedHousehold => _isNew && isSingleHeaded == true;

  /// True once every backend-required field is present — same
  /// "cheap pre-check" role as `FamilyRegistrationDraft.isSubmittable`.
  bool get isSubmittable {
    if (evacuationEventId == null || sex == null || ageBracket == null) {
      return false;
    }
    return switch (householdMode) {
      HouseholdMode.existing =>
        existingFamilyRemoteId != null || existingFamilyLocalId != null,
      HouseholdMode.new_ =>
        (newHouseholdHeadName?.trim().isNotEmpty ?? false) &&
            newHouseholdBarangayId != null,
    };
  }

  /// Whether this entry is actually ready to be sent to the backend
  /// right now — distinct from [isSubmittable] (a form-completeness
  /// check): an existing-household entry that still only has a
  /// [existingFamilyLocalId] (its household hasn't been assigned a
  /// real backend id yet) is complete but not yet syncable.
  bool get isReadyToSync {
    if (!isSubmittable) return false;
    if (householdMode == HouseholdMode.existing) {
      return existingFamilyRemoteId != null;
    }
    return true;
  }

  /// The three tri-state answers take a record so "set to not yet
  /// known" (`(value: null)`) is distinguishable from "leave as is"
  /// (omitted).
  EcBoardEntryDraft copyWith({
    int? evacuationEventId,
    String? sex,
    AgeBracket? ageBracket,
    HouseholdMode? householdMode,
    int? existingFamilyRemoteId,
    bool clearExistingFamilyRemoteId = false,
    String? existingFamilyLocalId,
    bool clearExistingFamilyLocalId = false,
    String? newHouseholdHeadName,
    int? newHouseholdBarangayId,
    Set<PerPersonSectoralFlag>? sectoralFlags,
    bool? headIsSelf,
    ({bool? value})? isSingleHeaded,
    ({bool? value})? headIsMinor,
    ({String? value})? headSex,
  }) {
    return EcBoardEntryDraft(
      evacuationCenterId: evacuationCenterId,
      evacuationEventId: evacuationEventId ?? this.evacuationEventId,
      sex: sex ?? this.sex,
      ageBracket: ageBracket ?? this.ageBracket,
      householdMode: householdMode ?? this.householdMode,
      existingFamilyRemoteId: clearExistingFamilyRemoteId
          ? null
          : (existingFamilyRemoteId ?? this.existingFamilyRemoteId),
      existingFamilyLocalId: clearExistingFamilyLocalId
          ? null
          : (existingFamilyLocalId ?? this.existingFamilyLocalId),
      newHouseholdHeadName: newHouseholdHeadName ?? this.newHouseholdHeadName,
      newHouseholdBarangayId:
          newHouseholdBarangayId ?? this.newHouseholdBarangayId,
      sectoralFlags: sectoralFlags ?? this.sectoralFlags,
      headIsSelf: headIsSelf ?? this.headIsSelf,
      isSingleHeaded: isSingleHeaded == null
          ? this.isSingleHeaded
          : isSingleHeaded.value,
      headIsMinor: headIsMinor == null ? this.headIsMinor : headIsMinor.value,
      headSex: headSex == null ? this.headSex : headSex.value,
    );
  }

  /// The real `POST /evacuation-centers/{id}/evacuees` body — only
  /// ever called once [isReadyToSync] is true. Exactly the fields the
  /// web dashboard sends for the same answers.
  Map<String, dynamic> toJson() => {
    'evacuation_event_id': evacuationEventId,
    'sex': sex,
    'age_bracket': ageBracket!.wireValue,
    'household_mode': householdMode.wireValue,
    if (householdMode == HouseholdMode.existing) ...{
      'family_id': existingFamilyRemoteId,
      // Only ever set for a household with no head linked yet.
      if (headIsSelf) 'head_is_self': true,
    } else ...{
      'family_name': newHouseholdHeadName?.trim(),
      'barangay_id': newHouseholdBarangayId,
      'head_is_self': headIsSelf,
      'is_single_headed': isSingleHeaded,
      if (!headIsSelf) ...{'head_sex': headSex, 'head_is_minor': headIsMinor},
    },
    // Only ticked flags, as true — an unticked one is left out entirely,
    // which the backend stores as "not recorded" (null).
    for (final flag in sectoralFlags) flag.wireValue: true,
  };
}
