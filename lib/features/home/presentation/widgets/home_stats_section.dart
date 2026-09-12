import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/dashboard_summary.dart';

/// Shows only values that are either directly counted from real data
/// or honestly derived (see [DataFreshness]'s own doc comment) — no
/// "available centers" count, since the backend's `status` field
/// vocabulary isn't confirmed reliably enough to compute that without
/// risking a wrong number.
///
/// Each tile carries a coloured left-edge accent and small icon — the
/// same KPI-card motif as the web admin dashboard's stat row (Total
/// Evacuees / Active Centers / Predicted Influx / Centers at Risk),
/// so the two surfaces read as one product rather than two different
/// designs. The accent colour itself always tracks what the tile
/// actually reports (e.g. the freshness tile's colour follows
/// [DataFreshness], not a fixed per-position colour) — it's never
/// decorative-only.
class HomeStatsSection extends StatelessWidget {
  const HomeStatsSection({
    super.key,
    required this.totalCenters,
    required this.alertCount,
    required this.freshness,
    required this.isLoading,
  });

  final int? totalCenters;
  final int? alertCount;
  final DataFreshness freshness;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Column(
        children: [
          Row(
            children: [
              Expanded(child: _StatTileSkeleton()),
              SizedBox(width: 12),
              Expanded(child: _StatTileSkeleton()),
            ],
          ),
          SizedBox(height: 12),
          _StatTileSkeleton(),
        ],
      );
    }

    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final l10n = AppLocalizations.of(context);
    final hasAlerts = (alertCount ?? 0) > 0;

    // A two-column grid for the two count metrics, with the data-
    // freshness tile as its own full-width row below — it's a status
    // readout rather than a count, so it reads better with room for a
    // longer label ("Unavailable") than a cramped third column would
    // allow.
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: l10n.statEvacuationCenters,
                value: totalCenters?.toString() ?? l10n.noDataYet,
                icon: Icons.home_work_outlined,
                accentColor: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: l10n.statPublicAlerts,
                value: alertCount?.toString() ?? l10n.noDataYet,
                icon: Icons.campaign_outlined,
                // Neutral when there's nothing to report yet (null) or
                // genuinely zero; only colours as a warning once
                // there's at least one real alert to flag.
                accentColor: hasAlerts
                    ? semantic.warning
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatTile(
          label: l10n.statDataStatus,
          value: _freshnessLabel(freshness, l10n),
          icon: _freshnessIcon(freshness),
          accentColor: _freshnessColor(freshness, theme, semantic),
          fullWidth: true,
        ),
      ],
    );
  }

  static String _freshnessLabel(
    DataFreshness freshness,
    AppLocalizations l10n,
  ) {
    return switch (freshness) {
      DataFreshness.live => l10n.live,
      DataFreshness.cached => l10n.cached,
      DataFreshness.offline => l10n.offline,
      DataFreshness.unavailable => l10n.unavailable,
    };
  }

  static IconData _freshnessIcon(DataFreshness freshness) {
    return switch (freshness) {
      DataFreshness.live => Icons.bolt,
      DataFreshness.cached => Icons.save_outlined,
      DataFreshness.offline => Icons.cloud_off_outlined,
      DataFreshness.unavailable => Icons.error_outline,
    };
  }

  static Color _freshnessColor(
    DataFreshness freshness,
    ThemeData theme,
    AppSemanticColors semantic,
  ) {
    return switch (freshness) {
      DataFreshness.live => semantic.success,
      DataFreshness.cached => semantic.warning,
      DataFreshness.offline => theme.colorScheme.onSurfaceVariant,
      DataFreshness.unavailable => theme.colorScheme.error,
    };
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decoration = BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: theme.colorScheme.outline),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withValues(alpha: 0.06),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );

    final iconChip = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: accentColor, size: 19),
    );

    if (fullWidth) {
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: decoration,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          children: [
            iconChip,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(color: accentColor),
            ),
          ],
        ),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            iconChip,
            const SizedBox(height: 10),
            // FittedBox rather than a plain Text: a longer value like
            // "Unavailable" could otherwise wrap awkwardly or crowd the
            // tile — this scales the text down just enough to fit
            // instead, never overflowing.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTileSkeleton extends StatelessWidget {
  const _StatTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingSkeleton(height: 22, width: 32),
            SizedBox(height: 6),
            LoadingSkeleton(height: 12, width: 60),
          ],
        ),
      ),
    );
  }
}
