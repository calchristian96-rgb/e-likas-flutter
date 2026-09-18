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
  });

  final AgeBracket? ageBracket;
  final int maleCount;
  final int femaleCount;

  int get total => maleCount + femaleCount;
}

/// One row of `GET /evacuation-centers/{id}/quick-count`'s
/// `sectoral_groups` breakdown — confirmed against
/// `EvacuationCenterQuickCountResource` on `elikas-backend-main (10)`.
/// **Read-only** here: this is a manually-reported aggregate number
/// staff enter separately (`PUT .../quick-count`, a web-dashboard
/// action), never something this app writes — `POST
/// /evacuation-centers/{id}/evacuees` ("Add Evacuee") has no
/// sector-related field in its validation rules at all, confirmed
/// directly against the controller. Always all 8 categories, zero-
/// filled by the backend for any category with no reported count yet
/// — never partial.
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

/// The live, "last known" breakdown for one center+event — fetched
/// on demand only (see `ecBoardQuickCountProvider`'s doc comment),
/// never cached offline: this is explicitly a server-computed
/// snapshot of *synced* data, kept visually separate from this
/// device's own still-pending entries rather than merged with them.
class EcBoardQuickCount {
  const EcBoardQuickCount({
    required this.ageGroups,
    this.sectoralGroups = const [],
  });

  final List<EcBoardAgeGroupCount> ageGroups;

  /// Read-only, staff-reported aggregate — see
  /// [EcBoardSectoralGroupCount]'s doc comment. Never editable from
  /// this app; shown for visibility only.
  final List<EcBoardSectoralGroupCount> sectoralGroups;

  int get totalMale => ageGroups.fold(0, (sum, g) => sum + g.maleCount);
  int get totalFemale => ageGroups.fold(0, (sum, g) => sum + g.femaleCount);
}
