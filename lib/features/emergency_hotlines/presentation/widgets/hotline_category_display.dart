import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/hotline.dart';

/// Icon/color/label for a [HotlineCategory] — lifted out of what was a
/// private method pair on [HotlineCard] so the new category section
/// headers can show the exact same icon/color/label as the cards inside
/// them, matching the established pattern
/// (`alertTypeDisplay.dart`/`center_status_display.dart`/
/// `hazard_polygon_layer.dart`) rather than growing a fourth private
/// copy of "map an enum to how it's shown."
IconData hotlineCategoryIcon(HotlineCategory category) {
  return switch (category) {
    HotlineCategory.nationalEmergency => Icons.emergency,
    HotlineCategory.disasterResponse => Icons.support_agent,
    HotlineCategory.fire => Icons.local_fire_department,
    HotlineCategory.police => Icons.local_police,
    HotlineCategory.medical => Icons.medical_services_outlined,
    HotlineCategory.rescue => Icons.health_and_safety,
    HotlineCategory.socialWelfare => Icons.groups_outlined,
    HotlineCategory.utility => Icons.water_drop_outlined,
  };
}

Color hotlineCategoryColor(HotlineCategory category, ThemeData theme) {
  final semantic = theme.extension<AppSemanticColors>()!;
  return switch (category) {
    HotlineCategory.nationalEmergency => theme.colorScheme.error,
    HotlineCategory.fire => theme.colorScheme.error,
    HotlineCategory.disasterResponse => theme.colorScheme.primary,
    HotlineCategory.police => theme.colorScheme.primary,
    HotlineCategory.medical => semantic.success,
    HotlineCategory.rescue => theme.colorScheme.primary,
    HotlineCategory.socialWelfare => semantic.warning,
    HotlineCategory.utility => theme.colorScheme.tertiary,
  };
}

String hotlineCategoryLabel(BuildContext context, HotlineCategory category) {
  final l10n = AppLocalizations.of(context);
  return switch (category) {
    HotlineCategory.nationalEmergency => l10n.hotlineCategoryNationalEmergency,
    HotlineCategory.disasterResponse => l10n.hotlineCategoryDisasterResponse,
    HotlineCategory.fire => l10n.hotlineCategoryFire,
    HotlineCategory.police => l10n.hotlineCategoryPolice,
    HotlineCategory.medical => l10n.hotlineCategoryMedical,
    HotlineCategory.rescue => l10n.hotlineCategoryRescue,
    HotlineCategory.socialWelfare => l10n.hotlineCategorySocialWelfare,
    HotlineCategory.utility => l10n.hotlineCategoryUtility,
  };
}

/// Display order for category sections — national emergency is shown
/// via its own priority card (see [PriorityHotlineCard]), not a
/// section, so it's excluded here. A category with no real hotline
/// entries in it simply produces an empty section that the page skips
/// — this list is a display *order*, not a claim that every category
/// necessarily has data. Ordered roughly by urgency: disaster/fire/
/// police/medical/rescue (immediate-response services) before social
/// welfare/utility (non-emergency municipal services).
const hotlineCategorySectionOrder = [
  HotlineCategory.disasterResponse,
  HotlineCategory.fire,
  HotlineCategory.police,
  HotlineCategory.medical,
  HotlineCategory.rescue,
  HotlineCategory.socialWelfare,
  HotlineCategory.utility,
];
