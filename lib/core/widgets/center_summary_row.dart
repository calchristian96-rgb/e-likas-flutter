import 'package:flutter/material.dart';

import '../../features/evacuation_centers/domain/entities/evacuation_center.dart';
import '../../features/evacuation_centers/presentation/widgets/center_status_display.dart';
import '../utils/distance_formatter.dart';
import 'status_badge.dart';

/// A compact single-line-per-field row for a center in a list of
/// several — "Other Nearby Centers" on Nearest Center today, and
/// anywhere else a center needs a lighter presentation than the full
/// [EvacuationCenterCard]. Only ever shows fields that are actually
/// present ([EvacuationCenter.distanceMeters]/occupancy are both
/// nullable depending on which endpoint the center came from) — never
/// a fabricated placeholder for a missing one.
class CenterSummaryRow extends StatelessWidget {
  const CenterSummaryRow({super.key, required this.center, this.onTap});

  final EvacuationCenter center;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = centerStatusColor(context, center);
    final distance = center.distanceMeters;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    center.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (distance != null)
                        Text(
                          formatDistanceAway(distance),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      StatusBadge(
                        label: localizedCenterStatus(context, center.status),
                        color: statusColor,
                      ),
                      if (center.hasOccupancyData)
                        Text(
                          '${center.currentOccupancy} / ${center.capacityPersons}',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
