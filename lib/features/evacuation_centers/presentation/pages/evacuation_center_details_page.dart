import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/map_launcher.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/occupancy_progress.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/evacuation_center.dart';
import '../providers/evacuation_centers_provider.dart';
import '../widgets/center_facilities_section.dart';
import '../widgets/center_photo_card.dart';
import '../widgets/center_status_display.dart';

/// Full detail view for a single evacuation center, reached by tapping
/// a card/row anywhere in the app. Everything except the Facilities
/// section is built entirely from [EvacuationCenter] — every other
/// field shown here is one the public `/public/evacuation-centers`
/// response actually returns (confirmed against
/// `PublicController::evacuationCenters()`). The Facilities section
/// (`CenterFacilitiesSection`) is the one part of this page that makes
/// its own request, to `GET public/evacuation-centers/{id}` — added on
/// `elikas-backend-main (7)` — since the list endpoint above never
/// carries facilities data. Deliberately still no Contact section:
/// `camp_manager_name`/`camp_manager_contact` only exist on the
/// staff-facing `EvacuationCenterResource` — the controller's own
/// comment says camp manager contact details are intentionally excluded
/// from public viewing (confirmed unchanged on the new detail endpoint
/// too) — so this app has no real data for it and doesn't pretend
/// otherwise.
class EvacuationCenterDetailsPage extends ConsumerWidget {
  const EvacuationCenterDetailsPage({super.key, required this.centerId});

  final int centerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final centerAsync = ref.watch(centerByIdProvider(centerId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.centerDetailsTitle)),
      body: centerAsync.when(
        data: (center) {
          if (center == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ErrorState(message: l10n.centerNotFound),
              ),
            );
          }
          return _CenterDetailsBody(center: center);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorState(
              message: '${l10n.couldNotLoadCenters} — $error',
              onRetry: () => ref.invalidate(centerByIdProvider(centerId)),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterDetailsBody extends StatelessWidget {
  const _CenterDetailsBody({required this.center});

  final EvacuationCenter center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final statusColor = centerStatusColor(context, center);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Header — icon, name, address, status.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.home_work_outlined, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(center.name, style: theme.textTheme.headlineSmall),
                  if (center.displayLocation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      center.displayLocation,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  StatusBadge(
                    label: localizedCenterStatus(context, center.status),
                    color: statusColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CenterPhotoCard(centerId: center.id, photoUrl: center.photoUrl),
        const Divider(height: 32),

        // Overview — capacity/occupancy/available slots/percent, only
        // ever the real fields this center actually has.
        Text(l10n.overviewSectionTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatChip(
              label: l10n.overviewCapacity,
              value: '${center.capacityPersons}',
            ),
            if (center.currentOccupancy != null)
              _StatChip(
                label: l10n.overviewCurrentOccupancy,
                value: '${center.currentOccupancy}',
              ),
            if (center.availableSlots != null)
              _StatChip(
                label: l10n.overviewAvailableSlots,
                value: '${center.availableSlots}',
              ),
            if (center.occupancyPercent != null)
              _StatChip(
                label: l10n.overviewOccupancyPercent,
                value: '${center.occupancyPercent!.toStringAsFixed(0)}%',
              ),
          ],
        ),
        if (center.hasOccupancyData) ...[
          const SizedBox(height: 14),
          OccupancyProgress(
            current: center.currentOccupancy!,
            capacity: center.capacityPersons,
            percent: center.occupancyPercent!,
            color: statusColor,
          ),
        ],
        const Divider(height: 32),

        // Location — real address, no fabricated map-preview image;
        // Get Directions/View on Map are the actions, matching every
        // other center surface in this app.
        Text(l10n.locationSectionTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                Icons.place_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  center.displayLocation.isNotEmpty
                      ? center.displayLocation
                      : l10n.addressUnavailable,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        if (!center.hasCoordinates) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.centerMapLocationUnavailable,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            // Hidden rather than disabled when there's no location to
            // navigate to, same reasoning as EvacuationCenterCard.
            if (center.hasCoordinates) ...[
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _handleGetDirections(context, center),
                  icon: const Icon(Icons.directions_outlined, size: 18),
                  label: Text(l10n.getDirections),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/map'),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text(l10n.viewOnMap),
              ),
            ),
          ],
        ),
        const Divider(height: 32),

        // Facilities — its own independently-loading/erroring section
        // (see CenterFacilitiesSection's doc comment), so a slow or
        // failed facilities request never affects anything above.
        Text(l10n.facilitiesSectionTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 10),
        CenterFacilitiesSection(centerId: center.id),
      ],
    );
  }

  static Future<void> _handleGetDirections(
    BuildContext context,
    EvacuationCenter center,
  ) async {
    if (!center.hasCoordinates) return;
    final opened = await openDirections(
      latitude: center.latitude!,
      longitude: center.longitude!,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).unableToOpenMaps)),
      );
    }
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
