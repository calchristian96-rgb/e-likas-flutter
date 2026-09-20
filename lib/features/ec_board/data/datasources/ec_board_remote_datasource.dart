import '../../../../core/network/staff_api_client.dart';
import '../../domain/entities/age_bracket.dart';
import '../../domain/entities/ec_board_entry_draft.dart' show EcBoardSubmitResult;
import '../../domain/entities/ec_board_quick_count.dart';
import '../../domain/entities/quick_departure_request.dart';
import '../../domain/entities/sectoral_group.dart';
import '../../domain/entities/sectoral_group_draft.dart';

/// The four EC Information Board endpoints: `POST .../evacuees`,
/// `GET`/`PUT .../quick-count`, and `POST .../quick-departure`.
class EcBoardRemoteDataSource {
  EcBoardRemoteDataSource(this._client);

  final StaffApiClient _client;

  /// [EcBoardSubmitResult.evacueeId] is a **top-level** response
  /// field, deliberately read from the envelope directly rather than
  /// `data['id']` (which is the *family's* id, not the evacuee's — a
  /// real bug already caught and fixed in the desktop app's equivalent
  /// work); [EcBoardSubmitResult.familyId] is that `data['id']` field,
  /// the FamilyResource the backend always returns regardless of
  /// [HouseholdMode] — see that class's doc comment for why the caller
  /// needs both.
  Future<EcBoardSubmitResult> createEvacuee(
    int centerId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.post(
      '/evacuation-centers/$centerId/evacuees',
      data: payload,
    );
    final envelope = response.data as Map<String, dynamic>;
    final data = envelope['data'] as Map<String, dynamic>;
    return EcBoardSubmitResult(
      evacueeId: envelope['evacuee_id'] as int,
      familyId: data['id'] as int,
    );
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
    return _parseQuickCount(data);
  }

  /// `PUT /evacuation-centers/{id}/quick-count` — confirmed directly
  /// against `EvacuationCenterController::updateQuickCount()`. Returns
  /// the freshly-saved figures the same way [getQuickCount] does, so a
  /// caller doesn't need a second GET to refresh its "last known" view
  /// after a successful save.
  Future<EcBoardQuickCount> updateQuickCount(
    int centerId,
    SectoralGroupDraft draft,
  ) async {
    final response = await _client.put(
      '/evacuation-centers/$centerId/quick-count',
      data: draft.toJson(),
    );
    final envelope = response.data as Map<String, dynamic>;
    final data = envelope['data'] as Map<String, dynamic>;
    return _parseQuickCount(data);
  }

  /// `POST /evacuation-centers/{id}/quick-departure` — the response
  /// carries only a `message` (e.g. "3 evacuee(s) marked as
  /// departed."), no `data` payload, so that confirmation message is
  /// returned directly rather than this trying to hand back a partial
  /// `EcBoardQuickCount`; the caller re-fetches [getQuickCount] itself
  /// to see the updated "Now" figures.
  Future<String> quickDeparture(QuickDepartureRequest request) async {
    final response = await _client.post(
      '/evacuation-centers/${request.evacuationCenterId}/quick-departure',
      data: request.toJson(),
    );
    final envelope = response.data as Map<String, dynamic>;
    return envelope['message'] as String? ?? '';
  }

  static EcBoardQuickCount _parseQuickCount(Map<String, dynamic> data) {
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
    final rawTotal = data['age_groups_total'] as Map<String, dynamic>?;
    final updatedAtRaw = data['updated_at'] as String?;
    return EcBoardQuickCount(
      familiesCumulative: (data['families_cumulative'] as num?)?.toInt() ?? 0,
      familiesNow: (data['families_now'] as num?)?.toInt() ?? 0,
      personsCumulative: (data['persons_cumulative'] as num?)?.toInt() ?? 0,
      personsNow: (data['persons_now'] as num?)?.toInt() ?? 0,
      beneficiaries4ps: (data['beneficiaries_4ps'] as num?)?.toInt() ?? 0,
      ageGroups: ageGroups,
      ageGroupsTotal: EcBoardAgeGroupTotal(
        maleCount: (rawTotal?['male_count'] as num?)?.toInt() ?? 0,
        femaleCount: (rawTotal?['female_count'] as num?)?.toInt() ?? 0,
        totalPersons: (rawTotal?['total_persons'] as num?)?.toInt() ?? 0,
      ),
      sectoralGroups: sectoralGroups,
      updatedByName: data['updated_by_name'] as String?,
      updatedAt: updatedAtRaw == null ? null : DateTime.tryParse(updatedAtRaw),
    );
  }

  /// Parsed defensively — an entry whose `age_bracket` is null/absent
  /// (or the literal string `"unclassified"`) is the trailing
  /// unclassified bucket, per the endpoint's own documented shape;
  /// count fields default to 0 rather than crashing parsing for a
  /// bracket the response happens to omit entirely. `total_count` is
  /// only ever present on that unclassified row (see
  /// `EcBoardAgeGroupCount.totalCount`'s doc comment) — absent
  /// elsewhere, so it stays null rather than defaulting to 0 and
  /// silently overriding `male_count + female_count` on a normal row.
  static EcBoardAgeGroupCount _parseAgeGroup(Map<String, dynamic> json) {
    final rawBracket = json['age_bracket'] as String?;
    return EcBoardAgeGroupCount(
      ageBracket: rawBracket == 'unclassified'
          ? null
          : AgeBracket.fromWire(rawBracket),
      maleCount: (json['male_count'] as num?)?.toInt() ?? 0,
      femaleCount: (json['female_count'] as num?)?.toInt() ?? 0,
      totalCount: (json['total_count'] as num?)?.toInt(),
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
