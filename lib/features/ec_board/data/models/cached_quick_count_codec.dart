import 'dart:convert';

import '../../domain/entities/age_bracket.dart';
import '../../domain/entities/ec_board_quick_count.dart';
import '../../domain/entities/sectoral_group.dart';

/// Round-trips [EcBoardQuickCount] to/from the JSON text stored in
/// `CachedQuickCounts.dataJson` — a private encoding of the entity's
/// own fields, not a copy of the backend's wire shape (unlike
/// `EcBoardRemoteDataSource`'s parsing, which must match the backend
/// exactly). Kept separate from that remote parsing on purpose: this
/// only ever needs to read back exactly what [encode] just wrote, so
/// it's free to shape the JSON however's simplest here.
class CachedQuickCountCodec {
  const CachedQuickCountCodec._();

  static String encode(EcBoardQuickCount count) => jsonEncode({
    'familiesCumulative': count.familiesCumulative,
    'familiesNow': count.familiesNow,
    'personsCumulative': count.personsCumulative,
    'personsNow': count.personsNow,
    'beneficiaries4ps': count.beneficiaries4ps,
    'ageGroups': [
      for (final g in count.ageGroups)
        {
          'ageBracket': g.ageBracket?.wireValue,
          'maleCount': g.maleCount,
          'femaleCount': g.femaleCount,
          'totalCount': g.totalCount,
        },
    ],
    'ageGroupsTotal': {
      'maleCount': count.ageGroupsTotal.maleCount,
      'femaleCount': count.ageGroupsTotal.femaleCount,
      'totalPersons': count.ageGroupsTotal.totalPersons,
    },
    'sectoralGroups': [
      for (final g in count.sectoralGroups)
        {
          'group': g.group?.wireValue,
          'maleCount': g.maleCount,
          'femaleCount': g.femaleCount,
        },
    ],
    'updatedByName': count.updatedByName,
    'updatedAt': count.updatedAt?.toIso8601String(),
  });

  static EcBoardQuickCount decode(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    final updatedAtRaw = map['updatedAt'] as String?;
    return EcBoardQuickCount(
      familiesCumulative: map['familiesCumulative'] as int,
      familiesNow: map['familiesNow'] as int,
      personsCumulative: map['personsCumulative'] as int,
      personsNow: map['personsNow'] as int,
      beneficiaries4ps: map['beneficiaries4ps'] as int,
      ageGroups: [
        for (final raw in (map['ageGroups'] as List))
          _decodeAgeGroup(raw as Map<String, dynamic>),
      ],
      ageGroupsTotal: _decodeAgeGroupTotal(
        map['ageGroupsTotal'] as Map<String, dynamic>,
      ),
      sectoralGroups: [
        for (final raw in (map['sectoralGroups'] as List))
          _decodeSectoralGroup(raw as Map<String, dynamic>),
      ],
      updatedByName: map['updatedByName'] as String?,
      updatedAt: updatedAtRaw == null ? null : DateTime.parse(updatedAtRaw),
      isFromCache: true,
    );
  }

  static EcBoardAgeGroupCount _decodeAgeGroup(Map<String, dynamic> raw) {
    return EcBoardAgeGroupCount(
      ageBracket: AgeBracket.fromWire(raw['ageBracket'] as String?),
      maleCount: raw['maleCount'] as int,
      femaleCount: raw['femaleCount'] as int,
      totalCount: raw['totalCount'] as int?,
    );
  }

  static EcBoardAgeGroupTotal _decodeAgeGroupTotal(Map<String, dynamic> raw) {
    return EcBoardAgeGroupTotal(
      maleCount: raw['maleCount'] as int,
      femaleCount: raw['femaleCount'] as int,
      totalPersons: raw['totalPersons'] as int,
    );
  }

  static EcBoardSectoralGroupCount _decodeSectoralGroup(
    Map<String, dynamic> raw,
  ) {
    return EcBoardSectoralGroupCount(
      group: SectoralGroup.fromWire(raw['group'] as String?),
      maleCount: raw['maleCount'] as int,
      femaleCount: raw['femaleCount'] as int,
    );
  }
}
