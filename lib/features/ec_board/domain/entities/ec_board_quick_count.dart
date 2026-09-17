import 'age_bracket.dart';

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

/// The live, "last known" breakdown for one center+event — fetched
/// on demand only (see `ecBoardQuickCountProvider`'s doc comment),
/// never cached offline: this is explicitly a server-computed
/// snapshot of *synced* data, kept visually separate from this
/// device's own still-pending entries rather than merged with them.
class EcBoardQuickCount {
  const EcBoardQuickCount({required this.ageGroups});

  final List<EcBoardAgeGroupCount> ageGroups;

  int get totalMale => ageGroups.fold(0, (sum, g) => sum + g.maleCount);
  int get totalFemale => ageGroups.fold(0, (sum, g) => sum + g.femaleCount);
}
