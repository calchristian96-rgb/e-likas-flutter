import 'dart:convert';

import '../../domain/entities/sectoral_group.dart';
import '../../domain/entities/sectoral_group_draft.dart';

/// Data-layer shape of one pending sectoral/4Ps edit — the in-memory
/// object `EcBoardLocalDataSource` reads/writes to Drift. Mirrors
/// `PendingEcBoardEntryModel`'s role, one aggregate instead of a list.
class PendingQuickCountEditModel {
  const PendingQuickCountEditModel({
    required this.evacuationCenterId,
    required this.evacuationEventId,
    required this.ownerStaffId,
    required this.beneficiaries4ps,
    required this.sectoralGroups,
    required this.syncStatus,
    this.attemptCount = 0,
    this.lastAttemptAtEpochMs,
    this.lastErrorCategory,
    this.lastErrorMessage,
    required this.createdAtEpochMs,
    required this.updatedAtEpochMs,
  });

  final int evacuationCenterId;
  final int evacuationEventId;
  final int ownerStaffId;
  final int beneficiaries4ps;
  final List<SectoralGroupEntry> sectoralGroups;
  final String syncStatus;
  final int attemptCount;
  final int? lastAttemptAtEpochMs;
  final String? lastErrorCategory;
  final String? lastErrorMessage;
  final int createdAtEpochMs;
  final int updatedAtEpochMs;

  PendingQuickCountEditModel copyWith({
    int? beneficiaries4ps,
    List<SectoralGroupEntry>? sectoralGroups,
    String? syncStatus,
    int? attemptCount,
    int? lastAttemptAtEpochMs,
    String? lastErrorCategory,
    bool clearLastErrorCategory = false,
    String? lastErrorMessage,
    bool clearLastErrorMessage = false,
    int? updatedAtEpochMs,
  }) {
    return PendingQuickCountEditModel(
      evacuationCenterId: evacuationCenterId,
      evacuationEventId: evacuationEventId,
      ownerStaffId: ownerStaffId,
      beneficiaries4ps: beneficiaries4ps ?? this.beneficiaries4ps,
      sectoralGroups: sectoralGroups ?? this.sectoralGroups,
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
    );
  }

  /// Encodes [sectoralGroups] for `PendingQuickCountEdits
  /// .sectoralGroupsJson` — see that column's own doc comment for why
  /// this is one JSON blob rather than 16 separate columns.
  static String encodeSectoralGroups(List<SectoralGroupEntry> groups) {
    return jsonEncode([
      for (final entry in groups)
        {
          'sectoral_group': entry.group.wireValue,
          'male_count': entry.maleCount,
          'female_count': entry.femaleCount,
        },
    ]);
  }

  /// Decodes [encodeSectoralGroups]'s output back into entries, always
  /// filling in every one of the 8 categories (zero-filled for any
  /// missing from the stored JSON) — mirrors the backend's own
  /// never-partial guarantee for this table, so a caller never has to
  /// separately handle "this category isn't in the list yet."
  static List<SectoralGroupEntry> decodeSectoralGroups(String json) {
    final raw = jsonDecode(json) as List;
    final byGroup = <SectoralGroup, SectoralGroupEntry>{
      for (final item in raw.cast<Map<String, dynamic>>())
        if (SectoralGroup.fromWire(item['sectoral_group'] as String?)
            case final group?)
          group: SectoralGroupEntry(
            group: group,
            maleCount: (item['male_count'] as num?)?.toInt() ?? 0,
            femaleCount: (item['female_count'] as num?)?.toInt() ?? 0,
          ),
    };
    return [
      for (final group in sectoralGroupValues)
        byGroup[group] ??
            SectoralGroupEntry(group: group, maleCount: 0, femaleCount: 0),
    ];
  }
}
