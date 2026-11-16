import 'package:flutter/material.dart';

/// One headline figure.
class StatItem {
  const StatItem(this.label, this.value, {this.alert = false});

  final String label;
  final String value;

  /// An alert state: the figure in red, with its word (web `.stat-alert`).
  final bool alert;
}

/// The web's stat strip: one bordered card of 3–4 figures, two per row
/// on a phone, the answer before the detail (design rule 2).
class StatStrip extends StatelessWidget {
  const StatStrip({super.key, required this.items});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          runSpacing: 16,
          children: [
            for (final item in items)
              FractionallySizedBox(
                widthFactor: 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      item.value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: item.alert ? theme.colorScheme.error : null,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
