/// The 8 sectoral categories `EvacuationCenterQuickCount::SECTORAL_GROUPS`
/// defines on the backend — confirmed directly against
/// `app/Models/EvacuationCenterQuickCount.php` and
/// `EvacuationCenterController::updateQuickCount()`'s validation rules
/// on `elikas-backend-main (10)`.
///
/// **Read-only in this app.** This is a manually-reported aggregate
/// count per center+event (`PUT /evacuation-centers/{id}/quick-count`,
/// a staff-web-dashboard action), never a per-evacuee field —
/// `POST /evacuation-centers/{id}/evacuees` ("Add Evacuee")'s own
/// validation rules were checked directly and do not accept any
/// sector-related field at all. See `EcBoardQuickCount.sectoralGroups`'s
/// doc comment for why that's a deliberate backend design choice, not
/// a gap.
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
