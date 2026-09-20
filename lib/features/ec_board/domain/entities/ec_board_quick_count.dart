import 'age_bracket.dart';
import 'sectoral_group.dart';

/// One row of `GET /evacuation-centers/{id}/quick-count`'s
/// `age_groups` breakdown — [ageBracket] is null only for the trailing
/// "unclassified" entry the backend appends (evacuees whose bracket
/// couldn't be determined), parsed defensively rather than assumed to
/// always be present in a fixed position.
class EcBoardAgeGroupCount {
  const EcBoardAgeGroupCount({
    required this.ageBracket,
    required this.maleCount,
    required this.femaleCount,
    this.totalCount,
  });

  final AgeBracket? ageBracket;
  final int maleCount;
  final int femaleCount;

  /// Only ever present on the unclassified row — confirmed against
  /// `EvacuationCenterQuickCount::liveAgeSexBreakdown()`'s own
  /// docblock: it's the FULL unclassified headcount, including anyone
  /// whose *sex* is unknown too, which [maleCount] + [femaleCount]
  /// alone would silently miss. Every other row has no such gap
  /// ([total] already covers it), so this stays null there.
  final int? totalCount;

  int get total => totalCount ?? (maleCount + femaleCount);
}

/// `GET`/`PUT .../quick-count`'s `age_groups_total` — the backend's own
/// authoritative sum, used directly instead of re-deriving one
/// client-side from [EcBoardQuickCount.ageGroups] (which would repeat
/// the exact male+female-undercounts-unclassified mistake
/// [EcBoardAgeGroupCount.totalCount] exists to avoid).
class EcBoardAgeGroupTotal {
  const EcBoardAgeGroupTotal({
    required this.maleCount,
    required this.femaleCount,
    required this.totalPersons,
  });

  final int maleCount;
  final int femaleCount;
  final int totalPersons;
}

/// One row of `GET /evacuation-centers/{id}/quick-count`'s
/// `sectoral_groups` breakdown — confirmed against
/// `EvacuationCenterQuickCountResource` on the real backend. A
/// manually-reported aggregate number (`PUT .../quick-count`) rather
/// than something derived from individual evacuee records — `POST
/// /evacuation-centers/{id}/evacuees` ("Add Evacuee") has no
/// sector-related field in its validation rules at all, confirmed
/// directly against the controller, and the backend's own docblock
/// explains why: sectoral flags are only known once a family's full
/// details are filled in, well after the fast headcount. Always all 8
/// categories, zero-filled by the backend for any category with no
/// reported count yet — never partial. Editable from this app via the
/// sectoral/4Ps edit flow (see `SectoralGroupDraft`), same offline
/// queue-then-sync pattern as Add Evacuee.
class EcBoardSectoralGroupCount {
  const EcBoardSectoralGroupCount({
    required this.group,
    required this.maleCount,
    required this.femaleCount,
  });

  final SectoralGroup? group;
  final int maleCount;
  final int femaleCount;

  int get total => maleCount + femaleCount;
}

/// The live, "last known" breakdown for one center+event — a
/// server-computed snapshot of *synced* data, kept visually separate
/// from this device's own still-pending entries rather than merged
/// with them. Fetched fresh on every page open when there's a
/// connection; the most recent successful fetch is also cached
/// locally (see `EcBoardRepository.getQuickCount`) so this "last
/// known" figure is still genuinely available — not just an error —
/// when staff open the board offline, matching this app's own
/// established "network-first, cache fallback" pattern for every
/// other lookup (e.g. `LookupRepositoryImpl`).
class EcBoardQuickCount {
  const EcBoardQuickCount({
    required this.familiesCumulative,
    required this.familiesNow,
    required this.personsCumulative,
    required this.personsNow,
    required this.beneficiaries4ps,
    required this.ageGroups,
    required this.ageGroupsTotal,
    this.sectoralGroups = const [],
    this.updatedByName,
    this.updatedAt,
    this.isFromCache = false,
  });

  /// Every family/person ever recorded arriving at this center for
  /// this event — server-incremented on arrival (`Add Evacuee`,
  /// full registration, or a household repointed here), never
  /// decremented, so this only ever grows. Distinct from [familiesNow]
  /// /[personsNow], which is who's still physically here right now.
  final int familiesCumulative;
  final int familiesNow;
  final int personsCumulative;
  final int personsNow;

  /// The standalone "4Ps Beneficiary Families" header count —
  /// manually-reported family-level total, distinct from the
  /// individual person-level male/female counts on the sectoral
  /// table's own `four_ps_beneficiary` row. Editable via the same
  /// sectoral/4Ps edit flow.
  final int beneficiaries4ps;

  final List<EcBoardAgeGroupCount> ageGroups;

  /// The backend's own authoritative total row — always equals
  /// [personsNow] exactly (see [EcBoardAgeGroupTotal]'s doc comment),
  /// used directly instead of re-summing [ageGroups] client-side.
  final EcBoardAgeGroupTotal ageGroupsTotal;

  /// Manually-reported aggregate — see [EcBoardSectoralGroupCount]'s
  /// doc comment.
  final List<EcBoardSectoralGroupCount> sectoralGroups;

  /// Who last saved the sectoral/4Ps figures, and when — null when
  /// nothing has ever been reported for this center+event yet (the
  /// backend hands back a fresh, unsaved instance in that case rather
  /// than 404ing).
  final String? updatedByName;
  final DateTime? updatedAt;

  /// True when this came from the local cache of the last successful
  /// fetch rather than a live request just now — the fetch itself
  /// failed (offline, timeout, server error) and this is the fallback,
  /// same "the app couldn't reach the server to reconfirm this"
  /// signal `StaffSession.isFromCache` gives for a restored session.
  final bool isFromCache;
}
