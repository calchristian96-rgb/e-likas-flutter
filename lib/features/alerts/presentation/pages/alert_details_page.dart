import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;

import '../../../../core/error/failure.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/alert.dart';
import '../providers/alerts_summary_provider.dart';
import '../widgets/alert_type_display.dart';

/// Full text and context for a single alert, reached by tapping a row
/// in the Alerts list.
///
/// Exists mainly because the list has to truncate: [AlertListTile]
/// caps the message at two lines, and an emergency instruction that
/// ends in an ellipsis is worse than useless. This screen is the only
/// place the complete message text is shown, so nothing here truncates.
class AlertDetailsPage extends ConsumerWidget {
  const AlertDetailsPage({super.key, required this.alertId});

  final int alertId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final alertAsync = ref.watch(alertByIdProvider(alertId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.alertDetailsTitle),
        actions: [
          if (alertAsync.hasValue)
            IconButton(
              tooltip: l10n.shareAlert,
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _shareAlert(context, alertAsync.value!, l10n),
            ),
        ],
      ),
      body: alertAsync.when(
        data: (alert) => _AlertDetailsBody(alert: alert),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorState(
              message: _describeError(error, l10n),
              onRetry: () => ref.invalidate(alertByIdProvider(alertId)),
            ),
          ),
        ),
      ),
    );
  }

  String _describeError(Object error, AppLocalizations l10n) {
    if (error is Failure) return error.message;
    return '${l10n.couldNotLoadAlerts} — $error';
  }

  /// Title + message + date/time, plainly labelled as coming from
  /// E-LIKAS — no location, no device info, nothing beyond what's
  /// already shown on screen.
  Future<void> _shareAlert(
    BuildContext context,
    Alert alert,
    AppLocalizations l10n,
  ) async {
    final when = alert.dateSent != null
        ? DateFormat('MMMM d, y · h:mm a').format(alert.dateSent!)
        : l10n.dateUnavailable;
    final text = 'E-LIKAS — ${alert.title}\n\n${alert.message}\n\n$when';
    await SharePlus.instance.share(ShareParams(text: text));
  }
}

class _AlertDetailsBody extends StatelessWidget {
  const _AlertDetailsBody({required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final typeColor = alertDisplayColor(
      context,
      alert.alertType,
      alert.severity,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _SeverityCard(alert: alert, color: typeColor),
        const SizedBox(height: 20),
        Text(l10n.additionalInformation, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _DetailRow(
          icon: Icons.priority_high,
          label: l10n.severityLabel,
          value: alertSeverityLabel(context, alert.severity),
        ),
        _DetailRow(
          icon: Icons.category_outlined,
          label: l10n.alertTypeLabel,
          value: alertTypeLabel(alert.alertType),
        ),
        _DetailRow(
          icon: Icons.schedule_outlined,
          label: l10n.receivedLabel,
          value: alert.dateSent != null
              ? DateFormat('EEEE, MMMM d, y · h:mm a').format(alert.dateSent!)
              : l10n.dateUnavailable,
        ),
        ..._buildContextRows(context),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/centers'),
          icon: const Icon(Icons.home_work_outlined, size: 18),
          label: Text(l10n.viewEvacuationCenters),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  /// The three fields the Home Dashboard's minimal slice deferred. Each
  /// is optional — and each row is simply omitted when its value is
  /// null, rather than rendered as an empty or "Unknown" row. Since
  /// these field names aren't confirmed against a real API response
  /// yet, an omitted row is the honest presentation: the app doesn't
  /// know, so it says nothing rather than asserting an absence.
  List<Widget> _buildContextRows(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      if (alert.evacuationEventName != null)
        _DetailRow(
          icon: Icons.event_outlined,
          label: l10n.evacuationEvent,
          value: alert.evacuationEventName!,
        ),
      if (alert.senderName != null)
        _DetailRow(
          icon: Icons.account_balance_outlined,
          label: l10n.sentBy,
          value: alert.senderName!,
        ),
      if (alert.recipientSummary != null)
        _DetailRow(
          icon: Icons.groups_outlined,
          label: l10n.sentTo,
          value: alert.recipientSummary!,
        ),
    ];
  }
}

/// The top card: severity badge, title, full message. Replaces the
/// previous separate "type chip row + title + message" layout with one
/// visually cohesive card so the alert's urgency is the first thing
/// read, matching the reference design — still built only from real
/// `AlertResource` fields (no affected-barangay list, no wind-speed/
/// rainfall-outlook/storm-movement/recommended-actions rows, none of
/// which the backend returns for an alert).
class _SeverityCard extends StatelessWidget {
  const _SeverityCard({required this.alert, required this.color});

  final Alert alert;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                alertDisplayIcon(alert.alertType, alert.severity),
                color: color,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatusBadge(
                  label: alertDisplayLabel(
                    context,
                    alert.alertType,
                    alert.severity,
                  ),
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(alert.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            alert.dateSent != null
                ? DateFormat('EEEE, MMMM d, y · h:mm a').format(alert.dateSent!)
                : l10n.dateUnavailable,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: 28),
          // No maxLines and no overflow handling anywhere in this widget
          // — the entire point of the screen. SelectableText so a
          // resident can copy an address or a hotline out of the message
          // body without retyping it.
          SelectableText(
            alert.message,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
