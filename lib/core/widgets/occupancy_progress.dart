import 'package:flutter/material.dart';

/// "120 / 500 (24%)" plus a thin colour-coded progress bar — the
/// occupancy readout every screen showing a center with real occupancy
/// data uses (card, Nearest Center, Center Details, the map's bottom
/// sheet). Callers are responsible for only rendering this when
/// [EvacuationCenter.hasOccupancyData] is true — this widget doesn't
/// guess at a percentage from partial data.
class OccupancyProgress extends StatelessWidget {
  const OccupancyProgress({
    super.key,
    required this.current,
    required this.capacity,
    required this.percent,
    required this.color,
    this.showBar = true,
  });

  final int current;
  final int capacity;
  final double percent;
  final Color color;
  final bool showBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              '$current / $capacity (${percent.toStringAsFixed(0)}%)',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        if (showBar) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ],
    );
  }
}
