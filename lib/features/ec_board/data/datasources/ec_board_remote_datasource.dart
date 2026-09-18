import '../../../../core/network/staff_api_client.dart';
import '../../domain/entities/age_bracket.dart';
import '../../domain/entities/ec_board_quick_count.dart';
import '../../domain/entities/sectoral_group.dart';

/// The two EC Information Board endpoints:
/// `POST /evacuation-centers/{id}/evacuees` and
/// `GET /evacuation-centers/{id}/quick-count`.
class EcBoardRemoteDataSource {
  EcBoardRemoteDataSource(this._client);

  final StaffApiClient _client;

  /// Returns the backend's `evacuee_id` — a **top-level** response
  /// field, deliberately read from the envelope directly rather than
  /// `data['id']` (which is the *family's* id, not the evacuee's — a
  /// real bug already caught and fixed in the desktop app's equivalent
  /// work, so this reads the correct field from the start here).
  Future<int> createEvacuee(int centerId, Map<String, dynamic> payload) async {
    final response = await _client.post(
      '/evacuation-centers/$centerId/evacuees',
      data: payload,
    );
    final envelope = response.data as Map<String, dynamic>;
    return envelope['evacuee_id'] as int;
  }

  Future<EcBoardQuickCount> getQuickCount({
    required int centerId,
    required int evacuationEventId,
  }) async {
    final response = await _client.get(
      '/evacuation-centers/$centerId/quick-count',
      queryParameters: {'evacuation_event_id': evacuationEventId},
    );
    final envelope = response.data as Map<String, dynamic>;
    final data = envelope['data'] as Map<String, dynamic>;
    final rawGroups = data['age_groups'] as List? ?? const [];
    final ageGroups = [
      for (final entry in rawGroups)
        _parseAgeGroup(entry as Map<String, dynamic>),
    ];
    final rawSectoral = data['sectoral_groups'] as List? ?? const [];
    final sectoralGroups = [
      for (final entry in rawSectoral)
        _parseSectoralGroup(entry as Map<String, dynamic>),
    ];
    return EcBoardQuickCount(
      ageGroups: ageGroups,
      sectoralGroups: sectoralGroups,
    );
  }

  /// Parsed defensively — an entry whose `age_bracket` is null/absent
  /// (or the literal string `"unclassified"`) is the trailing
  /// unclassified bucket, per the endpoint's own documented shape;
  /// count fields default to 0 rather than crashing parsing for a
  /// bracket the response happens to omit entirely.
  static EcBoardAgeGroupCount _parseAgeGroup(Map<String, dynamic> json) {
    final rawBracket = json['age_bracket'] as String?;
    return EcBoardAgeGroupCount(
      ageBracket: rawBracket == 'unclassified'
          ? null
          : AgeBracket.fromWire(rawBracket),
      maleCount: (json['male_count'] as num?)?.toInt() ?? 0,
      femaleCount: (json['female_count'] as num?)?.toInt() ?? 0,
    );
  }

  static EcBoardSectoralGroupCount _parseSectoralGroup(
    Map<String, dynamic> json,
  ) {
    return EcBoardSectoralGroupCount(
      group: SectoralGroup.fromWire(json['sectoral_group'] as String?),
      maleCount: (json['male_count'] as num?)?.toInt() ?? 0,
      femaleCount: (json['female_count'] as num?)?.toInt() ?? 0,
    );
  }
}
