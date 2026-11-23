import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../evacuation_centers/presentation/widgets/center_status_display.dart';
import '../../../staff_home/barangay_dashboard.dart';
import '../providers/own_centers_provider.dart';

/// What a center still needs before it is ready (0.4.0 Part 5).
enum CenterNeed { capacityMissing, capacityEstimated, location, checklist }

/// Each center's `readiness` from `GET /dashboard/barangay`, by id.
final centerReadinessProvider = Provider.autoDispose<Map<int, Object?>>((ref) {
  final d = ref.watch(barangayDashboardProvider).value;
  return {
    for (final c in d?.centers ?? const <Map<String, dynamic>>[])
      if (c['id'] is num) (c['id'] as num).toInt(): c['readiness'],
  };
});

/// The needs of [center]: from the public copy (capacity source, map
/// location) and the dashboard's readiness (the facilities checklist,
/// and anything the public copy cannot tell, e.g. for a pending center).
Set<CenterNeed> centerNeeds(OwnCenter center, Object? readiness) {
  final needs = <CenterNeed>{};
  final public = center.public;
  if (public != null) {
    if (public.isCapacityUnknown) needs.add(CenterNeed.capacityMissing);
    if (public.isCapacityEstimated) needs.add(CenterNeed.capacityEstimated);
    if (!public.hasCoordinates) needs.add(CenterNeed.location);
  }
  if (readiness is Map) {
    bool no(List<String> keys) => keys.any((k) => readiness[k] == false);
    if (no(['has_capacity', 'capacity'])) needs.add(CenterNeed.capacityMissing);
    if (readiness['capacity_source'] == 'estimated') {
      needs.add(CenterNeed.capacityEstimated);
    }
    if (no(['has_location', 'location'])) needs.add(CenterNeed.location);
    if (no(['has_checklist', 'facilities_checklist', 'checklist'])) {
      needs.add(CenterNeed.checklist);
    }
    final missing = readiness['missing'];
    if (missing is List) {
      for (final m in missing.map((e) => '$e'.toLowerCase())) {
        if (m.contains('checklist') || m.contains('facilit')) {
          needs.add(CenterNeed.checklist);
        } else if (m.contains('location')) {
          needs.add(CenterNeed.location);
        } else if (m.contains('estimat')) {
          needs.add(CenterNeed.capacityEstimated);
        } else if (m.contains('capacity')) {
          needs.add(CenterNeed.capacityMissing);
        }
      }
    }
  }
  if (needs.contains(CenterNeed.capacityMissing)) {
    needs.remove(CenterNeed.capacityEstimated);
  }
  return needs;
}

/// "Needs details" chips on a center card.
class CenterNeedsChips extends ConsumerWidget {
  const CenterNeedsChips({super.key, required this.center});

  final OwnCenter center;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final readiness = ref.watch(centerReadinessProvider)[center.id];
    final needs = centerNeeds(center, readiness);
    if (needs.isEmpty) return const SizedBox.shrink();
    final warning = theme.extension<AppSemanticColors>()!.warning;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(l10n.centerNeedsDetails, style: theme.textTheme.labelMedium),
          for (final n in CenterNeed.values)
            if (needs.contains(n))
              Chip(
                visualDensity: VisualDensity.compact,
                avatar: Icon(
                  switch (n) {
                    CenterNeed.capacityMissing ||
                    CenterNeed.capacityEstimated => Icons.straighten,
                    CenterNeed.location => Icons.location_off_outlined,
                    CenterNeed.checklist => Icons.checklist_rtl_outlined,
                  },
                  size: 16,
                  color: warning,
                ),
                label: Text(switch (n) {
                  CenterNeed.capacityMissing => l10n.centerNeedCapacity,
                  CenterNeed.capacityEstimated => l10n.centerNeedCapacityEst,
                  CenterNeed.location => l10n.centerNeedLocation,
                  CenterNeed.checklist => l10n.centerNeedChecklist,
                }),
                side: BorderSide(color: warning.withValues(alpha: 0.5)),
              ),
        ],
      ),
    );
  }
}

/// How full a center is, as a bar in its status colour (amber when
/// nearly full, red when full). Nothing for an unknown capacity, which
/// is never full.
class CenterFillBar extends StatelessWidget {
  const CenterFillBar({
    super.key,
    required this.occupancy,
    required this.capacity,
    required this.status,
  });

  final int occupancy;
  final int? capacity;
  final String status;

  @override
  Widget build(BuildContext context) {
    final cap = capacity;
    if (cap == null || cap <= 0) return const SizedBox.shrink();
    final share = (occupancy / cap).clamp(0.0, 1.0);
    final color = switch (status) {
      'full' || 'nearly_full' => centerStatusColorOf(status),
      _ when share >= 0.9 => centerStatusColorOf('full'),
      _ => centerStatusColorOf('active'),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: share,
          minHeight: 8,
          backgroundColor: color.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          semanticsValue: '${(share * 100).round()}%',
        ),
      ),
    );
  }
}
