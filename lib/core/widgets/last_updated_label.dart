import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// "Updated just now" / "Updated 5m ago" / "Updated at 3:45 PM" —
/// shows `null` as "Not yet updated" rather than hiding silently, so
/// it's always clear whether the dashboard has ever successfully
/// loaded anything.
class LastUpdatedLabel extends StatelessWidget {
  const LastUpdatedLabel({super.key, required this.timestamp});

  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Text(_label(timestamp), style: style);
  }

  static String _label(DateTime? timestamp) {
    if (timestamp == null) return 'Not yet updated';

    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
    return 'Updated at ${DateFormat('MMM d, h:mm a').format(timestamp)}';
  }
}
