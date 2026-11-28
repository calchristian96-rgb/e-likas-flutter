import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../utils/formatters.dart';

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
    this.estimated = false,
    this.resident = false,
  });

  /// The capacity is an estimate: "48 / 112 est." ("(estimated)" for
  /// residents).
  final bool estimated;
  final bool resident;

  final int current;
  final int capacity;
  final double percent;
  final Color color;
  final bool showBar;

  String _figure(BuildContext context) {
    final figure = '${formatCount(current)} / ${formatCount(capacity)}';
    if (!estimated) return figure;
    final l10n = AppLocalizations.of(context);
    return resident
        ? l10n.capacityResidentEstimated(figure)
        : l10n.capacityEstimated(figure);
  }

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
            Flexible(
              child: Text(
                '${_figure(context)} (${percent.toStringAsFixed(0)}%)',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        if (showBar) ...[
          const SizedBox(height: 6),
          // A square bar on a hairline frame, as on a printed legend.
          DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline,
                width: 1,
              ),
            ),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              minHeight: 8,
              borderRadius: BorderRadius.zero,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ],
    );
  }
}
