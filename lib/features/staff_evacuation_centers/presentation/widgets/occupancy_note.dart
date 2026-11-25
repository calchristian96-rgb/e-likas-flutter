import 'package:flutter/material.dart';

/// The server's `occupancy_note` under a center (backend d17f6de): who
/// else is inside for another open event, e.g. "87 people here for
/// Typhoon Drill". Shown as the server words it; nothing when null.
class OccupancyNote extends StatelessWidget {
  const OccupancyNote({super.key, required this.note});

  final String? note;

  @override
  Widget build(BuildContext context) {
    final text = note?.trim();
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.groups_outlined, size: 16, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
