import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../error/failure.dart';

/// The one lock design (0.4.0 Parts 1 and 2): a grey lock and a plain
/// sentence, never the red error look. Used when the event is still
/// being monitored ("Available when the event is Active"), when it is
/// closed, and for a 422 lock answer from the server ([message]).
class LockNote extends StatelessWidget {
  const LockNote({super.key, this.message, this.dense = false});

  /// The server's own words, or null for "Available when the event is
  /// Active".
  final String? message;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Semantics(
      container: true,
      label: l10n.lockTitle,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(dense ? 8 : 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message ?? l10n.lockAvailableWhenActive,
                style: theme.textTheme.bodyMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A snack bar for a failed staff action: an [EventLockFailure] gets the
/// lock icon and the server's message as it comes; anything else, the
/// message alone.
SnackBar failureSnackBar(Failure failure) {
  if (failure is EventLockFailure) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(failure.message)),
        ],
      ),
    );
  }
  return SnackBar(content: Text(failure.message));
}

/// Whether the selected event's status locks registration, relief,
/// transfers and final counts: only an Active event allows them.
bool eventAllowsFieldWork(String? status) => status == 'active';
