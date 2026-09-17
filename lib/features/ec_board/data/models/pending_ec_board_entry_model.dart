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
    );
  }
}
