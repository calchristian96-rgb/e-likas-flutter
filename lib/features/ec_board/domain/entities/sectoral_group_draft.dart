import 'sectoral_group.dart';

/// One category's male/female counts within a [SectoralGroupDraft] —
/// the editable counterpart to `EcBoardSectoralGroupCount`.
class SectoralGroupEntry {
  const SectoralGroupEntry({
    required this.group,
    required this.maleCount,
    required this.femaleCount,
  });

  final SectoralGroup group;
  final int maleCount;
  final int femaleCount;

  SectoralGroupEntry copyWith({int? maleCount, int? femaleCount}) {
    return SectoralGroupEntry(
      group: group,
      maleCount: maleCount ?? this.maleCount,
      femaleCount: femaleCount ?? this.femaleCount,
    );
  }
}

/// A full, editable snapshot of one center+event's sectoral/4Ps
/// figures — always carries all 8 [SectoralGroup] categories (never a
/// partial diff), so saving always expresses "this is the complete
/// current state" rather than "here's what changed." That matches
/// `updateQuickCount()`'s own `updateOrCreate`-per-category semantics
/// exactly and keeps last-write-wins simple: whichever draft syncs
/// last is the whole truth, not a merge candidate.
class SectoralGroupDraft {
  const SectoralGroupDraft({
    required this.evacuationCenterId,
    required this.evacuationEventId,
    required this.beneficiaries4ps,
    required this.sectoralGroups,
  });

  final int evacuationCenterId;
  final int evacuationEventId;
  final int beneficiaries4ps;

  /// Always exactly 8 entries, one per [SectoralGroup], in
  /// [sectoralGroupValues] order.
  final List<SectoralGroupEntry> sectoralGroups;

  SectoralGroupDraft copyWith({
    int? beneficiaries4ps,
    List<SectoralGroupEntry>? sectoralGroups,
  }) {
    return SectoralGroupDraft(
      evacuationCenterId: evacuationCenterId,
      evacuationEventId: evacuationEventId,
      beneficiaries4ps: beneficiaries4ps ?? this.beneficiaries4ps,
      sectoralGroups: sectoralGroups ?? this.sectoralGroups,
    );
  }

  SectoralGroupDraft updateGroup(
    SectoralGroup group, {
    int? maleCount,
    int? femaleCount,
  }) {
    return copyWith(
      sectoralGroups: [
        for (final entry in sectoralGroups)
          if (entry.group == group)
            entry.copyWith(maleCount: maleCount, femaleCount: femaleCount)
          else
            entry,
      ],
    );
  }

  /// The real `PUT /evacuation-centers/{id}/quick-count` request body
  /// — confirmed directly against `EvacuationCenterController
  /// ::updateQuickCount()`'s validation rules. Always sends all 8
  /// categories (see this class's own doc comment), never a subset.
  Map<String, dynamic> toJson() => {
    'evacuation_event_id': evacuationEventId,
    'beneficiaries_4ps': beneficiaries4ps,
    'sectoral_groups': [
      for (final entry in sectoralGroups)
        {
          'sectoral_group': entry.group.wireValue,
          'male_count': entry.maleCount,
          'female_count': entry.femaleCount,
        },
    ],
  };
}
