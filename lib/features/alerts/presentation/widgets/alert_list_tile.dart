import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/accent_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/alert.dart';
import 'alert_type_display.dart';

/// A single alert in the Alerts list.
///
/// Uses the shared [AccentCard] treatment — a left-edge bar in the
/// alert's own severity colour, the same motif [HomeStatsSection]'s
/// stat tiles and the evacuation center/hotline cards use — so an
/// evacuation alert reads as visually distinct from an advisory before
/// a resident even reads the text. The row is tappable, pushing
/// `/alerts/:id`; its icon/colour/badge come from the shared
/// [alertDisplayIcon]/[alertDisplayColor]/[alertDisplayLabel] mapping
/// (severity-first, `alert_type` as fallback) so the details screen
/// presents the same alert identically.
class AlertListTile extends StatelessWidget {
  const AlertListTile({super.key, required this.alert, this.isLatest = false});

  final Alert alert;

  /// True only when this tile is genuinely the most recent alert in the
  /// unfiltered feed *and* the list is currently shown in its default
  /// unfiltered, newest-first view — the caller is responsible for that
  /// condition, so this never mislabels a alert as "Latest" while a
  /// filter/search/different sort is active and it isn't positionally
  /// first any more. Not a backend "pinned" concept — the backend has
  /// none — just calling out data that's already there.
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = alertDisplayColor(context, alert.alertType, alert.severity);

    return AccentCard(
      accentColor: color,
      onTap: () => context.push('/alerts/${alert.id}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              alertDisplayIcon(alert.alertType, alert.severity),
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLatest) ...[
                    Text(
                      l10n.latestAlertLabel.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          alertDisplayLabel(
                            context,
                            alert.alertType,
                            alert.severity,
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.dateSent != null
                        ? DateFormat(
                            'MMM d, y · h:mm a',
                          ).format(alert.dateSent!)
                        : l10n.dateUnavailable,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // A quiet affordance that the row now goes somewhere —
            // without it, tappability is invisible until touched.
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
