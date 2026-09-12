import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Localized display label for a `facility_type` value — verified
/// against the exact 19-value enum in `database/migrations/
/// 2026_01_01_000006_create_evacuation_center_facilities_table.php`
/// on `elikas-backend-main (7)`. Same "don't invent, don't hide"
/// fallback as [localizedCenterStatus]/[localizedCenterType] for an
/// unrecognized value.
String localizedFacilityType(BuildContext context, String facilityType) {
  final l10n = AppLocalizations.of(context);
  return switch (facilityType) {
    'latrine_compost_pit' => l10n.facilityTypeLatrineCompostPit,
    'latrine_sealed' => l10n.facilityTypeLatrineSealed,
    'toilet_male' => l10n.facilityTypeToiletMale,
    'toilet_female' => l10n.facilityTypeToiletFemale,
    'toilet_common' => l10n.facilityTypeToiletCommon,
    'bathing_area_male' => l10n.facilityTypeBathingAreaMale,
    'bathing_area_female' => l10n.facilityTypeBathingAreaFemale,
    'bathing_area_common' => l10n.facilityTypeBathingAreaCommon,
    'handwashing_facility' => l10n.facilityTypeHandwashingFacility,
    'laundry_space' => l10n.facilityTypeLaundrySpace,
    'women_friendly_space' => l10n.facilityTypeWomenFriendlySpace,
    'child_friendly_space' => l10n.facilityTypeChildFriendlySpace,
    'health_facility' => l10n.facilityTypeHealthFacility,
    'prayer_room' => l10n.facilityTypePrayerRoom,
    'community_kitchen' => l10n.facilityTypeCommunityKitchen,
    'livestock_area' => l10n.facilityTypeLivestockArea,
    'camp_management_desk' => l10n.facilityTypeCampManagementDesk,
    'info_board' => l10n.facilityTypeInfoBoard,
    'storage_area' => l10n.facilityTypeStorageArea,
    _ => facilityType,
  };
}

/// The exact 19 backend `facility_type` enum values, in a fixed
/// display order — this is the checklist the Facilities section
/// renders, matching every value the API can ever send. A center's
/// `facilities` response only ever contains a *subset* of these (only
/// types staff have actually recorded), so the section reconciles
/// this fixed list against whatever subset came back rather than only
/// rendering what the API happened to include.
const evacuationCenterFacilityTypeValues = [
  'latrine_compost_pit',
  'latrine_sealed',
  'toilet_male',
  'toilet_female',
  'toilet_common',
  'bathing_area_male',
  'bathing_area_female',
  'bathing_area_common',
  'handwashing_facility',
  'laundry_space',
  'women_friendly_space',
  'child_friendly_space',
  'health_facility',
  'prayer_room',
  'community_kitchen',
  'livestock_area',
  'camp_management_desk',
  'info_board',
  'storage_area',
];
