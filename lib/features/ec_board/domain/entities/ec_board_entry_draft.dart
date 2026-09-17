import 'age_bracket.dart';

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

/// A single Add Evacuee entry — one person's EC Information Board
/// intake record. Deliberately far smaller than
/// `FamilyRegistrationDraft`: this is a fast, single-evacuee counting
/// tool (bracket + sex + which household), not a full registration.
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
    );
  }

  /// The real `POST /evacuation-centers/{id}/evacuees` body — only
  /// ever called once [isReadyToSync] is true.
  Map<String, dynamic> toJson() => {
    'evacuation_event_id': evacuationEventId,
    'sex': sex,
    'age_bracket': ageBracket!.wireValue,
    'household_mode': householdMode.wireValue,
    if (householdMode == HouseholdMode.existing)
      'family_id': existingFamilyRemoteId
    else ...{
      'family_name': newHouseholdHeadName?.trim(),
      'barangay_id': newHouseholdBarangayId,
    },
  };
}
