/// Household head answers exactly as stored — every one nullable, so an
/// entry queued before they existed reads as "not yet known" / not the
/// head. See `EcBoardEntryDraft.headIsSelf`.
typedef HeadAnswers = ({
  bool? headIsSelf,
  bool? isSingleHeaded,
  bool? headIsMinor,
  String? headSex,
});

const HeadAnswers noHeadAnswers = (
  headIsSelf: null,
  isSingleHeaded: null,
  headIsMinor: null,
  headSex: null,
);

/// Data-layer shape of one queued EC Board entry — the in-memory
/// object `EcBoardLocalDataSource` reads/writes to Drift. Mirrors
/// `PendingFamilyRegistrationModel`'s role exactly.
class PendingEcBoardEntryModel {
  const PendingEcBoardEntryModel({
    required this.localId,
    required this.evacuationCenterId,
    required this.evacuationEventId,
    required this.sex,
    required this.ageBracket,
    required this.householdMode,
    this.existingFamilyRemoteId,
    this.existingFamilyLocalId,
    this.newHouseholdHeadName,
    this.newHouseholdBarangayId,
    required this.householdLabel,
    required this.syncStatus,
    this.attemptCount = 0,
    this.lastAttemptAtEpochMs,
    this.lastErrorCategory,
    this.lastErrorMessage,
    required this.createdAtEpochMs,
    required this.updatedAtEpochMs,
    this.ownerStaffId,
    this.sectoralFlags = const {},
    this.head = noHeadAnswers,
  });

  final String localId;
  final int evacuationCenterId;
  final int evacuationEventId;
  final String sex;
  final String ageBracket;
  final String householdMode;
  final int? existingFamilyRemoteId;
  final String? existingFamilyLocalId;
  final String? newHouseholdHeadName;
  final int? newHouseholdBarangayId;
  final String householdLabel;
  final String syncStatus;
  final int attemptCount;
  final int? lastAttemptAtEpochMs;
  final String? lastErrorCategory;
  final String? lastErrorMessage;
  final int createdAtEpochMs;
  final int updatedAtEpochMs;
  final int? ownerStaffId;

  /// Wire names (`is_pwd`, …) of the sectoral flags ticked for this
  /// person — stored as six nullable bool columns (true or null), see
  /// `PendingEcBoardEntries`.
  final Set<String> sectoralFlags;

  /// The household head answers, stored as four nullable columns (see
  /// `PendingEcBoardEntries.headIsSelf`) — replaced as a whole on every
  /// save, never merged.
  final HeadAnswers head;

  PendingEcBoardEntryModel copyWith({
    int? evacuationEventId,
    String? sex,
    String? ageBracket,
    String? householdMode,
    int? existingFamilyRemoteId,
    bool clearExistingFamilyRemoteId = false,
    String? existingFamilyLocalId,
    bool clearExistingFamilyLocalId = false,
    String? newHouseholdHeadName,
    int? newHouseholdBarangayId,
    String? householdLabel,
    String? syncStatus,
    int? attemptCount,
    int? lastAttemptAtEpochMs,
    String? lastErrorCategory,
    bool clearLastErrorCategory = false,
    String? lastErrorMessage,
    bool clearLastErrorMessage = false,
    int? updatedAtEpochMs,
    int? ownerStaffId,
    Set<String>? sectoralFlags,
    HeadAnswers? head,
  }) {
    return PendingEcBoardEntryModel(
      localId: localId,
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
      householdLabel: householdLabel ?? this.householdLabel,
      syncStatus: syncStatus ?? this.syncStatus,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAtEpochMs: lastAttemptAtEpochMs ?? this.lastAttemptAtEpochMs,
      lastErrorCategory: clearLastErrorCategory
          ? null
          : (lastErrorCategory ?? this.lastErrorCategory),
      lastErrorMessage: clearLastErrorMessage
          ? null
          : (lastErrorMessage ?? this.lastErrorMessage),
      createdAtEpochMs: createdAtEpochMs,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
      ownerStaffId: ownerStaffId ?? this.ownerStaffId,
      sectoralFlags: sectoralFlags ?? this.sectoralFlags,
      head: head ?? this.head,
    );
  }
}
