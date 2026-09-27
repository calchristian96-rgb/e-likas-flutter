import 'sectoral_group.dart';

/// The six sectoral flags Add Evacuee can optionally record for the ONE
/// person being added — each a real per-evacuee column on the backend
/// (`evacuees.is_pwd` etc., accepted by `POST
/// /evacuation-centers/{id}/evacuees`). A ticked flag is sent as `true`;
/// an unticked one isn't sent at all, which the backend stores as null
/// ("not recorded" — never "no").
///
/// The other two [SectoralGroup]s, child-headed and single-headed
/// family, describe a whole household rather than a person, so they
/// have no flag here: they come from the household's head answers (see
/// `EcBoardEntryDraft.headIsSelf`).
///
/// Declared in the order the Add Evacuee form shows them.
enum PerPersonSectoralFlag {
  pwd,
  pregnant,
  lactating,
  soloParent,
  indigenousPerson,
  fourPsBeneficiary;

  /// The backend's own `evacuees` column / request field name.
  String get wireValue => switch (this) {
    PerPersonSectoralFlag.pwd => 'is_pwd',
    PerPersonSectoralFlag.pregnant => 'is_pregnant',
    PerPersonSectoralFlag.lactating => 'is_lactating',
    PerPersonSectoralFlag.soloParent => 'is_solo_parent',
    PerPersonSectoralFlag.indigenousPerson => 'is_indigenous_person',
    PerPersonSectoralFlag.fourPsBeneficiary => 'is_4ps_beneficiary',
  };

  /// The EC Board sectoral row this flag is counted in.
  SectoralGroup get sectoralGroup => switch (this) {
    PerPersonSectoralFlag.pwd => SectoralGroup.pwd,
    PerPersonSectoralFlag.pregnant => SectoralGroup.pregnantWomen,
    PerPersonSectoralFlag.lactating => SectoralGroup.lactatingMothers,
    PerPersonSectoralFlag.soloParent => SectoralGroup.soloParent,
    PerPersonSectoralFlag.indigenousPerson => SectoralGroup.indigenousPeoples,
    PerPersonSectoralFlag.fourPsBeneficiary => SectoralGroup.fourPsBeneficiary,
  };

  /// Only a female evacuee can carry these — the form hides and clears
  /// them for a male one, and the backend rejects them for a male one.
  bool get femaleOnly =>
      this == PerPersonSectoralFlag.pregnant ||
      this == PerPersonSectoralFlag.lactating;

  static PerPersonSectoralFlag? fromWire(String? value) {
    for (final flag in PerPersonSectoralFlag.values) {
      if (flag.wireValue == value) return flag;
    }
    return null;
  }
}
