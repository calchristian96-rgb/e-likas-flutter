import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../evacuation_centers/domain/entities/evacuation_center.dart';
import '../../../evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import '../../../family_registration/domain/entities/lookup_entities.dart';
import '../../../family_registration/presentation/providers/lookup_providers.dart';
import '../../../outbox/presentation/outbox_providers.dart';
import '../../../staff_auth/presentation/providers/staff_auth_provider.dart';

/// One of the signed-in official's centers: the staff row (which knows
/// about Unverified and rejected centers, and carries the figures for
/// the selected event) plus, when residents can see it, the public row,
/// used for the map location and photo only: it has no event, so its
/// count is everyone inside for every open event (backend d17f6de).
class OwnCenter {
  const OwnCenter({required this.center, this.public});

  final EvacuationCenterLookup center;

  /// Null for a pending or rejected center, which is not public.
  final EvacuationCenter? public;

  int get id => center.id;
  String get name => center.name;

  /// The status shown for the selected event.
  String get status => center.status;

  /// People inside for the selected event only; null when not known.
  int? get occupancy => center.currentOccupancy;
  double? get occupancyPercent => center.occupancyPercent;
  int? get capacity => center.capacityPersons ?? public?.capacityPersons;

  /// official | estimated | unknown: a property of the center (the
  /// public copy has it; the staff list does not).
  String get capacitySource =>
      public?.capacitySource ?? ((capacity ?? 0) > 0 ? 'official' : 'unknown');

  bool get isCapacityUnknown =>
      capacitySource == 'unknown' || (capacity ?? 0) <= 0;
  bool get isCapacityEstimated =>
      capacitySource == 'estimated' && !isCapacityUnknown;

  /// "87 people here for Typhoon Drill".
  String? get occupancyNote => center.occupancyNote;
}

/// The signed-in official's own barangay's centers, matched by
/// barangay id (never by name), sorted by name. CSWD (no barangay of
/// its own) gets every center the server shows it. Works offline from
/// the staff lookup cache.
final ownCentersProvider = FutureProvider.autoDispose<List<OwnCenter>>((
  ref,
) async {
  // A location sent from this phone changes the badges ("Edit waiting
  // for CSWD"): refetch the staff list after each sync.
  ref.listen(
    outboxRevisionProvider,
    (_, _) => ref.invalidate(evacuationCentersLookupProvider),
  );
  final session = await ref.watch(staffAuthProvider.future);
  final lookups = await ref.watch(evacuationCentersLookupProvider.future);
  var publicCenters = const <EvacuationCenter>[];
  try {
    publicCenters = await ref.watch(allEvacuationCentersProvider.future);
  } catch (_) {
    // No public copy yet: the staff rows alone are still the list.
  }
  final byId = {for (final c in publicCenters) c.id: c};
  final barangayId = session?.barangayId;
  return [
    for (final c in lookups)
      if (barangayId == null || c.barangayId == barangayId)
        OwnCenter(center: c, public: byId[c.id]),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
});
