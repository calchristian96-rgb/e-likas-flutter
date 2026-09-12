import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../alerts/domain/entities/alert.dart';
import '../../../alerts/presentation/widgets/alert_type_display.dart';
import 'section_header.dart';

/// Recent-alerts preview for the Home dashboard.
///
/// Shows the single most recent alert — [alertsSummaryProvider] only
/// carries `{latest, count}`, not a short list, so a 3-item preview
/// would require widening that provider's return shape. Left as a
/// clearly-labelled single item rather than done as a UI-only guess at
/// what a multi-item version should look like.
class LatestAlertCard extends StatelessWidget {
  const LatestAlertCard({
    super.key,
    required this.isLoading,
    required this.alert,
    required this.errorMessage,
    required this.onRetry,
  });

  final bool isLoading;
  final Alert? alert;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.recentAlerts,
          onViewAll: () => context.go('/alerts'),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: _buildBody(context),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (isLoading) {
      // A skeleton shaped like the real content (icon, title line,
      // message line) rather than a bare spinner — previews the
      // layout that's about to appear instead of just "something is
      // happening."
      return const Row(
        children: [
          LoadingSkeleton(height: 40, width: 40, borderRadius: 10),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(height: 14, width: 160),
                SizedBox(height: 8),
                LoadingSkeleton(height: 12),
              ],
            ),
          ),
        ],
      );
    }
    if (errorMessage != null) {
      return ErrorState(
        message: '${l10n.couldNotLoadAlerts} — $errorMessage',
        onRetry: onRetry,
      );
    }
    final currentAlert = alert;
    if (currentAlert == null) {
      final theme = Theme.of(context);
      final success = theme.extension<AppSemanticColors>()!.success;
      return Row(
        children: [
          Icon(Icons.check_circle_outline, color: success, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.noActiveAlerts,
                  style: theme.textTheme.titleSmall?.copyWith(color: success),
                ),
                const SizedBox(height: 2),
                Text(l10n.normalMonitoring, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      );
    }

    final theme = Theme.of(context);
    final color = alertDisplayColor(
      context,
      currentAlert.alertType,
      currentAlert.severity,
    );
    final icon = alertDisplayIcon(
      currentAlert.alertType,
      currentAlert.severity,
    );
    final label = alertDisplayLabel(
      context,
      currentAlert.alertType,
      currentAlert.severity,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/alerts/${currentAlert.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentAlert.title,
                        maxLines: 1,
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
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  currentAlert.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  currentAlert.dateSent != null
                      ? DateFormat(
                          'MMM d, y · h:mm a',
                        ).format(currentAlert.dateSent!)
                      : l10n.dateUnavailable,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
    );
  }
}
