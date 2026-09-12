import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/distance_formatter.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../../../core/widgets/accent_card.dart';
import '../../../../core/widgets/occupancy_progress.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/evacuation_center.dart';
import 'center_status_display.dart';

class EvacuationCenterCard extends StatelessWidget {
  const EvacuationCenterCard({super.key, required this.center});

  final EvacuationCenter center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final distance = center.distanceMeters;
    final accentColor = centerStatusColor(context, center);

    return AccentCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      accentColor: accentColor,
      onTap: () => context.push('/centers/${center.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    center.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(
                  label: localizedCenterStatus(context, center.status),
                  color: accentColor,
                  maxWidth: 110,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              center.displayLocation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (center.hasOccupancyData)
              OccupancyProgress(
                current: center.currentOccupancy!,
                capacity: center.capacityPersons,
                percent: center.occupancyPercent!,
                color: accentColor,
              ),
            if (distance != null) ...[
              if (center.hasOccupancyData) const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.directions_walk,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatDistanceAway(distance),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            // Hidden rather than disabled when there's no location to
            // navigate to — a visibly-disabled button here would imply
            // "directions are temporarily unavailable," when actually
            // this center simply has no coordinates at all yet.
            if (center.hasCoordinates) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _handleGetDirections(context, center),
                  icon: const Icon(Icons.directions_outlined, size: 18),
                  label: Text(l10n.getDirections),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(44, 40),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
