import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/data_freshness_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../alerts/domain/entities/alert.dart';
import '../../../alerts/presentation/widgets/alert_type_display.dart';
import '../../../barangay_status/domain/barangay_status.dart';

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
    this.situation,
  });

  /// The barangays' statuses in the open event. With no alert, the card
  /// says what is really happening ("Evacuation ordered in 2
  /// barangays") instead of "Normal Monitoring" while barangays
  /// evacuate.
  final BarangayStatusBoard? situation;

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
    // Its own space below, so a hidden card leaves no gap on Home.
    final card = _buildCard(context);
    if (card is SizedBox && card.child == null) return card;
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: card);
  }

  Widget _buildCard(BuildContext context) {
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
                  _Title(l10n.liveDataUnavailable),
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
    final board = situation;
    if (alert == null && board != null && board.hasOpenEvent) {
      final evacuating = board.barangays
          .where(
            (b) =>
                b.status == BarangayStatusKey.preemptiveEvacuation ||
                b.status == BarangayStatusKey.forcedEvacuation,
          )
          .length;
      final watching = board.barangays
          .where(
            (b) =>
                b.status == BarangayStatusKey.watch ||
                b.status == BarangayStatusKey.floodingReported,
          )
          .length;
      // An evacuation order is already the live strip across the top
      // (and the red banner for the resident's own barangay): this card
      // does not repeat it.
      if (evacuating > 0) return const SizedBox.shrink();
      final (color, icon, title, body) = watching > 0
          ? (
              semanticColors.warning,
              Icons.visibility_outlined,
              l10n.situationOnWatch,
              l10n.situationWatchingBarangays(watching),
            )
          : (
              theme.colorScheme.onSurfaceVariant,
              Icons.event_note_outlined,
              l10n.situationMonitoring,
              l10n.situationNoEvacuation,
            );
      return _CardShell(
        color: color,
        child: InkWell(
          onTap: () => context.go('/map'),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Title(title),
                    const SizedBox(height: 2),
                    Text(body, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      board.eventName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (board.isFromCache && board.lastSyncedAt != null)
                      Text(
                        l10n.residentStatusSavedCopy(
                          formatElapsedSince(board.lastSyncedAt!),
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      );
    }

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
                  _Title(l10n.normalMonitoringTitle),
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
              label: Text(l10n.findNearestCenterAction.toUpperCase()),
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
                minimumSize: const Size(48, 48),
              ),
              child: Text(l10n.viewAlert.toUpperCase()),
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
                minimumSize: const Size(48, 48),
              ),
              child: Text(l10n.viewAlert.toUpperCase()),
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
                minimumSize: const Size(48, 48),
              ),
              child: Text(l10n.viewDetails.toUpperCase()),
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

  /// The severity colour, carried by the card's icon; the plate itself
  /// stays map paper.
  final Color color;
  final Widget child;

  /// A mandatory alert: framed with the 2 px ink rule instead of a
  /// hairline (no tint, no shadow on the sheet).
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final p = SheetPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.plate,
        border: Border.all(
          color: p.rule,
          width: emphasized ? Sheet.frame : Sheet.hairline,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

/// A card title in ink condensed caps.
class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    semanticsLabel: text,
    style: SheetText.title(SheetPalette.of(context).ink, size: 22),
  );
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
            label: Text(action.label.toUpperCase()),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(48, 48),
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
