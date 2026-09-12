import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/cache/offline_cache_service.dart';
import '../../../../core/sync/sync_timestamps.dart';
import '../../../../core/utils/byte_size_formatter.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/last_updated_label.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../providers/offline_data_provider.dart';

class OfflineDataManagementPage extends ConsumerStatefulWidget {
  const OfflineDataManagementPage({super.key});

  @override
  ConsumerState<OfflineDataManagementPage> createState() =>
      _OfflineDataManagementPageState();
}

class _OfflineDataManagementPageState
    extends ConsumerState<OfflineDataManagementPage> {
  bool _isSyncing = false;
  bool _isClearing = false;

  Future<void> _handleUpdateAll() async {
    setState(() => _isSyncing = true);
    final ok = await ref.read(offlineDataOverviewProvider.notifier).syncAll();
    if (!mounted) return;
    setState(() => _isSyncing = false);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.syncCompleted : l10n.syncPartialFailure),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleClearCachedData() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearCacheDialogTitle),
        content: Text(l10n.clearCacheDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.clearCacheDialogConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isClearing = true);
    await ref.read(offlineDataOverviewProvider.notifier).clearCachedData();
    if (!mounted) return;
    setState(() => _isClearing = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.cacheCleared)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isConnected = ref.watch(connectivityStatusProvider).value ?? false;
    final overviewAsync = ref.watch(offlineDataOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.offlineDataManagementTitle)),
      body: overviewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorState(
            message: l10n.couldNotLoadOfflineData,
            onRetry: () => ref.invalidate(offlineDataOverviewProvider),
          ),
        ),
        data: (snapshot) {
          return ListView(
            // Extra bottom padding, matching HomePage's own ListView —
            // gives the last button (Clear Cached Data) breathing room
            // above a gesture-navigation bar instead of sitting flush
            // against the very bottom edge.
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                l10n.offlineDataManagementSubtitle,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isConnected ? Icons.wifi_outlined : Icons.wifi_off_outlined,
                    size: 15,
                    color: isConnected
                        ? theme.extension<AppSemanticColors>()!.success
                        : theme.extension<AppSemanticColors>()!.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isConnected ? l10n.online : l10n.offlineModeLabel,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Two Rows of Expanded tiles, not a GridView with a fixed
              // mainAxisExtent — a fixed cell height can never be
              // guaranteed to fit unbounded content (longer Filipino
              // labels, a multi-line LastUpdatedLabel caption, larger
              // Android font-scale settings), which is exactly what
              // caused a real "RenderFlex overflowed" crash here on a
              // physical device. IntrinsicHeight + CrossAxisAlignment
              // .stretch is the same technique AccentCard's own doc
              // comment already establishes elsewhere in this app for
              // the identical reason: it measures each row's tallest
              // tile first, then hands that as the row's real height,
              // so every tile in the row matches it — no size is
              // guessed or hardcoded.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _OverviewTile(
                        icon: Icons.storage_outlined,
                        label: l10n.offlineOverviewCachedRecords,
                        value: '${snapshot.totalRecords}',
                        accentColor: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _OverviewTile(
                        icon: Icons.sd_storage_outlined,
                        label: l10n.offlineOverviewStorageUsed,
                        value: formatBytes(snapshot.totalSizeBytes),
                        accentColor: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _OverviewTile(
                        icon: isConnected
                            ? Icons.wifi_outlined
                            : Icons.wifi_off_outlined,
                        label: l10n.settingsConnectivity,
                        value: isConnected
                            ? l10n.online
                            : l10n.offlineModeLabel,
                        accentColor: isConnected
                            ? theme.extension<AppSemanticColors>()!.success
                            : theme.extension<AppSemanticColors>()!.warning,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _OverviewTile(
                        icon: Icons.history_outlined,
                        label: l10n.offlineOverviewLastUpdated,
                        valueWidget: LastUpdatedLabel(
                          timestamp: snapshot.mostRecentSync,
                        ),
                        accentColor: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.cachedDataCategoriesTitle,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              _CategoryTile(
                icon: Icons.campaign_outlined,
                label: l10n.navAlerts,
                stats: snapshot.stats[CacheCategory.alerts],
                syncedAt: snapshot.syncedAt[SyncDomain.alerts],
                // The Alerts tab is a bottom-nav branch, not a pushed
                // page — `go`, not `push`, switches to it the same way
                // every other existing "jump to the Alerts tab" call
                // site in this app already does (see
                // `latest_alert_card.dart`/`home_page.dart`).
                onTap: () => context.go('/alerts'),
              ),
              const SizedBox(height: 8),
              _CategoryTile(
                icon: Icons.home_work_outlined,
                label: l10n.evacuationCentersTitle,
                stats: snapshot.stats[CacheCategory.evacuationCenters],
                syncedAt: snapshot.syncedAt[SyncDomain.evacuationCenters],
                // The centers list lives outside the bottom-nav shell,
                // pushed on top of whichever tab is active — same
                // `/centers` route every existing "view all centers"
                // entry point already pushes.
                onTap: () => context.push('/centers'),
              ),
              const SizedBox(height: 8),
              _CategoryTile(
                icon: Icons.map_outlined,
                label: l10n.hazardMapTitle,
                stats: snapshot.stats[CacheCategory.hazardMap],
                syncedAt: snapshot.syncedAt[SyncDomain.hazardMap],
                // GIS Map is a bottom-nav branch too — hazard areas
                // render on it directly, no separate hazard screen
                // exists or is needed.
                onTap: () => context.go('/map'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSyncing ? null : _handleUpdateAll,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_download_outlined, size: 18),
                  label: Text(l10n.updateAllData),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isClearing ? null : _handleClearCachedData,
                  icon: _isClearing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.delete_outline, size: 18),
                  label: Text(l10n.clearCachedData),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.icon,
    required this.label,
    required this.accentColor,
    this.value,
    this.valueWidget,
  }) : assert(
         value == null || valueWidget == null,
         'Pass either value or valueWidget, not both.',
       );

  final IconData icon;
  final String label;
  final Color accentColor;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: accentColor),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child:
                valueWidget ??
                Text(
                  value ?? '',
                  maxLines: 1,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            // 2 lines, not 1: the tile now grows to fit its content
            // (see the Row+Expanded+IntrinsicHeight change above), so a
            // longer Filipino/Bikol label can genuinely wrap instead of
            // needing to be cut off.
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.stats,
    required this.syncedAt,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final CacheCategoryStats? stats;
  final DateTime? syncedAt;

  /// Navigates to the real, existing screen this category's data feeds
  /// (Alerts tab / Centers list / GIS Map) — optional only so this
  /// widget doesn't force every future category to be tappable if one
  /// genuinely has nowhere to go.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final count = stats?.recordCount ?? 0;
    final hasData = count > 0;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasData
                      ? l10n.cachedItemsCount(count)
                      : l10n.noSavedDataForCategory,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (hasData) ...[
                  const SizedBox(height: 2),
                  LastUpdatedLabel(timestamp: syncedAt),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
