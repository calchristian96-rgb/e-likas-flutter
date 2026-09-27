/// The 8 sectoral categories `EvacuationCenterQuickCount::SECTORAL_GROUPS`
/// defines on the backend — confirmed directly against
/// `app/Models/EvacuationCenterQuickCount.php` and
/// the live breakdown `EvacuationCenterQuickCountResource` returns.
///
/// **Read-only in this app**, and nowhere typed in: the backend counts
/// every group live — the six per-person groups from each evacuee's Add
/// Evacuee flags (see `PerPersonSectoralFlag`), child-/single-headed
/// family from each household's head answers.
enum SectoralGroup {
  pwd,
  childHeadedFamily,
  singleHeadedFamily,
  soloParent,
  pregnantWomen,
  lactatingMothers,
  fourPsBeneficiary,
  indigenousPeoples;

  String get wireValue => switch (this) {
    SectoralGroup.pwd => 'pwd',
    SectoralGroup.childHeadedFamily => 'child_headed_family',
    SectoralGroup.singleHeadedFamily => 'single_headed_family',
    SectoralGroup.soloParent => 'solo_parent',
    SectoralGroup.pregnantWomen => 'pregnant_women',
    SectoralGroup.lactatingMothers => 'lactating_mothers',
    SectoralGroup.fourPsBeneficiary => 'four_ps_beneficiary',
    SectoralGroup.indigenousPeoples => 'indigenous_peoples',
  };

  static SectoralGroup? fromWire(String? value) => switch (value) {
    'pwd' => SectoralGroup.pwd,
    'child_headed_family' => SectoralGroup.childHeadedFamily,
    'single_headed_family' => SectoralGroup.singleHeadedFamily,
    'solo_parent' => SectoralGroup.soloParent,
    'pregnant_women' => SectoralGroup.pregnantWomen,
    'lactating_mothers' => SectoralGroup.lactatingMothers,
    'four_ps_beneficiary' => SectoralGroup.fourPsBeneficiary,
    'indigenous_peoples' => SectoralGroup.indigenousPeoples,
    _ => null,
  };
}

/// Fixed display order, matching the backend's own `SECTORAL_GROUPS`
/// constant (the EC Information Board template's own ordering).
const sectoralGroupValues = SectoralGroup.values;
