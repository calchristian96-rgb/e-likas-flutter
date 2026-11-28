import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../evacuation_centers/presentation/widgets/center_status_display.dart';
import '../../../staff_home/barangay_dashboard.dart';
import '../providers/own_centers_provider.dart';

/// What a center still needs before it is ready (0.4.0 Part 5).
/// [supplies]: the checklist is short of the standard for a full center.
enum CenterNeed {
  capacityMissing,
  capacityEstimated,
  location,
  checklist,
  supplies,
}

/// Each center's row from `GET /dashboard/barangay` `centers[]`, by id
/// (apps-api-2026-11-24.md 7.1): `readiness`, `has_location`,
/// `capacity_persons`, `capacity_source`.
final centerReadinessProvider =
    Provider.autoDispose<Map<int, Map<String, dynamic>>>((ref) {
      final d = ref.watch(barangayDashboardProvider).value;
      return {
        for (final c in d?.centers ?? const <Map<String, dynamic>>[])
          if (c['id'] is num) (c['id'] as num).toInt(): c,
      };
    });

/// The needs of [center]: from the public copy (capacity source, map
/// location) and its dashboard row [dashboard] (`readiness`, and the
/// capacity and location the public copy cannot tell, e.g. for a pending
/// center).
Set<CenterNeed> centerNeeds(OwnCenter center, Map<String, dynamic>? dashboard) {
  final needs = <CenterNeed>{};
  final public = center.public;
  if (public != null) {
    if (public.isCapacityUnknown) needs.add(CenterNeed.capacityMissing);
    if (public.isCapacityEstimated) needs.add(CenterNeed.capacityEstimated);
    if (!public.hasCoordinates) needs.add(CenterNeed.location);
  }
  if (dashboard != null) {
    if (dashboard.containsKey('capacity_persons') &&
        dashboard['capacity_persons'] == null) {
      needs.add(CenterNeed.capacityMissing);
    }
    if (dashboard['capacity_source'] == 'estimated') {
      needs.add(CenterNeed.capacityEstimated);
    }
    if (dashboard['has_location'] == false) needs.add(CenterNeed.location);
    switch (dashboard['readiness']) {
      case 'no_checklist':
        needs.add(CenterNeed.checklist);
      case 'no_capacity':
        needs.add(CenterNeed.capacityMissing);
      case 'below':
        needs.add(CenterNeed.supplies);
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
    final dashboard = ref.watch(centerReadinessProvider)[center.id];
    final needs = centerNeeds(center, dashboard);
    final semantic = theme.extension<AppSemanticColors>()!;
    if (needs.isEmpty) {
      // The checklist meets the standard for a full center.
      if (dashboard?['readiness'] != 'ready') return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Chip(
            visualDensity: VisualDensity.compact,
            avatar: Icon(Icons.verified, size: 16, color: semantic.success),
            label: Text(l10n.centerReady),
            side: BorderSide(color: semantic.success.withValues(alpha: 0.5)),
          ),
        ),
      );
    }
    final warning = semantic.warning;
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
                    CenterNeed.supplies => Icons.inventory_outlined,
                  },
                  size: 16,
                  color: warning,
                ),
                label: Text(switch (n) {
                  CenterNeed.capacityMissing => l10n.centerNeedCapacity,
                  CenterNeed.capacityEstimated => l10n.centerNeedCapacityEst,
                  CenterNeed.location => l10n.centerNeedLocation,
                  CenterNeed.checklist => l10n.centerNeedChecklist,
                  CenterNeed.supplies => l10n.centerNeedSupplies,
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
        borderRadius: BorderRadius.zero,
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
