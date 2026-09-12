import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../alerts/domain/entities/alert.dart';
import '../../../alerts/presentation/widgets/alert_type_display.dart';

/// Large status card at the top of the Home Dashboard — the one place
/// a resident should be able to tell, at a glance, exactly how urgent
/// the current situation is.
///
/// Strictly derived from real alert data — never invents disaster
/// type, severity, state, affected areas, or instructions the API
/// didn't provide. An unrecognized `alert_type` falls back to the
/// neutral "Advisory" label rather than guessing at what it might
/// mean. Backend-generated `title`/`message` are always shown
/// verbatim — only the surrounding chrome (badge wording, action
/// labels) is ever localized.
///
/// Five distinct visual states, driven entirely by [latestAlert]'s
/// real `severity` field: no active alert ("Normal Monitoring"), info,
/// advisory, mandatory, and all_clear — each with its own accent
/// colour (reusing the same [AppSemanticColors]/[ColorScheme] roles
/// every other severity/status surface in this app already uses, not
/// new hardcoded colours) and its own set of real, already-existing
/// actions. A severity this app doesn't recognise, or an older cached
/// alert with no `severity` field at all, gets the calmest treatment
/// (view-only) rather than an invented escalation.
class EmergencyStatusCard extends StatelessWidget {
  const EmergencyStatusCard({
    super.key,
    required this.latestAlert,
    required this.isLoading,
    this.isUnavailable = false,
    this.isOffline = false,
    this.lastChecked,
  });

  final Alert? latestAlert;
  final bool isLoading;

  /// True when the alerts fetch itself failed (backend error, no cache
  /// to fall back to) — distinct from "no alert to show," which would
  /// otherwise wrongly read as "all clear" when the real story is "we
  /// don't know."
  final bool isUnavailable;

  /// True when the device is currently offline — used only to caption
  /// a real alert as "showing saved information" rather than letting
  /// cached content quietly look live. Never used to fabricate a
  /// different alert or state.
  final bool isOffline;

  /// When the dashboard last successfully resolved alert data — shown
  /// in the "Normal Monitoring" state as "Last checked", using the
  /// same PST-formatted display convention as the rest of the app.
  /// Omitted entirely when null rather than showing a placeholder.
  final DateTime? lastChecked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>()!;
    final l10n = AppLocalizations.of(context);
    final alert = latestAlert;

    if (isLoading) {
      return _CardShell(
        color: theme.colorScheme.onSurfaceVariant,
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n.checkingForAlerts,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
      );
    }

    if (isUnavailable && alert == null) {
      return _CardShell(
        color: semanticColors.warning,
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 28,
              color: semanticColors.warning,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.liveDataUnavailable,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: semanticColors.warning,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(l10n.showingSavedInfo, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // NORMAL / NO ACTIVE ALERT — calm, green, no action strip. Never
    // hidden or skipped just because there's nothing urgent to show;
    // residents should be able to see confirmation that the app *did*
    // check and found nothing active, not silence.
    if (alert == null) {
      return _CardShell(
        color: semanticColors.success,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.verified_outlined,
              size: 30,
              color: semanticColors.success,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.normalMonitoringTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: semanticColors.success,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(l10n.normalMonitoring, style: theme.textTheme.bodySmall),
                  if (lastChecked != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.freshnessLastUpdatedVerb} '
                      '${DateFormat('MMM d, h:mm a').format(lastChecked!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    final color = alertDisplayColor(context, alert.alertType, alert.severity);
    final icon = alertDisplayIcon(alert.alertType, alert.severity);
    final label = alertDisplayLabel(context, alert.alertType, alert.severity);
    final isMandatory = isMandatorySeverity(alert.severity);

    return _CardShell(
      color: color,
      emphasized: isMandatory,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  alert.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(label: label, color: color, maxWidth: 110),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  alert.dateSent != null
                      ? DateFormat('MMM d, y · h:mm a').format(alert.dateSent!)
                      : l10n.dateUnavailable,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (isOffline) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${l10n.offline} • ${l10n.showingSavedAlertInfo}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          ..._buildActions(context, alert, color, isMandatory, l10n),
        ],
      ),
    );
  }

  /// Per-severity primary/secondary actions — every route pushed here
  /// already exists elsewhere in the app (bottom-nav destinations or
  /// existing quick actions); nothing new is wired for this card.
  ///
  /// - info (or an unrecognised/legacy severity with no field at all):
  ///   just "View Details", right-aligned, matching the original
  ///   compact treatment — no action strip.
  /// - advisory: "View Alert" as the primary action, plus a small
  ///   strip for Find Nearest Center / View Map.
  /// - mandatory: a full-width "Find Nearest Center" primary button
  ///   (the one action that matters most when it's genuinely urgent),
  ///   plus a strip for Evacuation Centers / Emergency Hotlines / View
  ///   Alert.
  /// - all_clear: "View Alert" only, same as advisory's primary — no
  ///   strip, since there's nothing left to shortcut to.
  List<Widget> _buildActions(
    BuildContext context,
    Alert alert,
    Color color,
    bool isMandatory,
    AppLocalizations l10n,
  ) {
    switch (alert.severity) {
      case 'mandatory':
        return [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push('/nearest-center'),
              icon: const Icon(Icons.near_me_outlined, size: 18),
              label: Text(l10n.findNearestCenterAction),
              style: FilledButton.styleFrom(backgroundColor: color),
            ),
          ),
          const SizedBox(height: 8),
          _EmergencyActionStrip(
            color: color,
            actions: [
              _EmergencyAction(
                icon: Icons.home_work_outlined,
                label: l10n.evacuationCentersTitle,
                onTap: () => context.push('/centers'),
              ),
              _EmergencyAction(
                icon: Icons.emergency_outlined,
                label: l10n.emergencyHotlines,
                onTap: () => context.push('/emergency-hotlines'),
              ),
              _EmergencyAction(
                icon: Icons.visibility_outlined,
                label: l10n.viewAlert,
                onTap: () => context.push('/alerts/${alert.id}'),
              ),
            ],
          ),
        ];

      case 'advisory':
        return [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/alerts/${alert.id}'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(44, 36),
                foregroundColor: color,
              ),
              child: Text(l10n.viewAlert),
            ),
          ),
          const SizedBox(height: 4),
          _EmergencyActionStrip(
            color: color,
            actions: [
              _EmergencyAction(
                icon: Icons.near_me_outlined,
                label: l10n.findNearestCenterAction,
                onTap: () => context.push('/nearest-center'),
              ),
              _EmergencyAction(
                icon: Icons.map_outlined,
                label: l10n.viewOnMap,
                onTap: () => context.go('/map'),
              ),
            ],
          ),
        ];

      case 'all_clear':
        return [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/alerts/${alert.id}'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(44, 36),
                foregroundColor: color,
              ),
              child: Text(l10n.viewAlert),
            ),
          ),
        ];

      case 'info':
      default:
        return [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/alerts/${alert.id}'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(44, 36),
                foregroundColor: color,
              ),
              child: Text(l10n.viewDetails),
            ),
          ),
        ];
    }
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.color,
    required this.child,
    this.emphasized = false,
  });

  final Color color;
  final Widget child;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        // A soft severity-tinted background — not just a coloured
        // border — so mandatory/advisory states read as visually
        // distinct at a glance without becoming a solid colour block.
        // Subtle enough (4%/8% alpha) that body text stays fully
        // readable regardless of the accent colour underneath it.
        color: Color.alphaBlend(
          color.withValues(alpha: emphasized ? 0.08 : 0.04),
          theme.cardColor,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: emphasized ? 0.55 : 0.3),
          width: emphasized ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

/// A compact row of small emergency-shortcut buttons — deliberately
/// smaller than Home's own Quick Actions grid tiles (this is a
/// same-card, in-context shortcut list, not a second Quick Actions
/// section). [Wrap], not a [Row]: on a narrow phone, or with longer
/// Filipino labels, or at a larger Android text-scale setting, three
/// buttons plus their icons and padding can genuinely not fit one line
/// — wrapping to a second row costs nothing when they do fit, and
/// avoids an overflow when they don't.
class _EmergencyActionStrip extends StatelessWidget {
  const _EmergencyActionStrip({required this.actions, required this.color});

  final List<_EmergencyAction> actions;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final action in actions)
          OutlinedButton.icon(
            onPressed: action.onTap,
            icon: Icon(action.icon, size: 16),
            label: Text(action.label),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(44, 36),
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: 0.4)),
            ),
          ),
      ],
    );
  }
}

class _EmergencyAction {
  const _EmergencyAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
