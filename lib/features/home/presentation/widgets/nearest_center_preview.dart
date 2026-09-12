import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/result.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../evacuation_centers/domain/entities/evacuation_center.dart';
import '../../../evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import '../../../evacuation_centers/presentation/widgets/center_status_display.dart';
import 'section_header.dart';

/// Home dashboard preview of the single nearest evacuation center.
///
/// Reuses exactly the same [locationServiceProvider] one-shot permission
/// flow and [nearestEvacuationCentersProvider] family provider that
/// NearestCenterPage already uses — no new location or data-fetching
/// logic, just a condensed presentation of the same result. If location
/// can't be resolved (services off, permission denied), that's shown
/// honestly as an unavailable state rather than fabricating a center.
class NearestCenterPreview extends ConsumerStatefulWidget {
  const NearestCenterPreview({super.key});

  @override
  ConsumerState<NearestCenterPreview> createState() =>
      _NearestCenterPreviewState();
}

class _NearestCenterPreviewState extends ConsumerState<NearestCenterPreview> {
  Result<({double latitude, double longitude})>? _position;

  @override
  void initState() {
    super.initState();
    _requestPosition();
  }

  Future<void> _requestPosition() async {
    setState(() => _position = null);
    final locationService = ref.read(locationServiceProvider);
    final result = await locationService.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _position = switch (result) {
        Success(:final value) => Success((
          latitude: value.latitude,
          longitude: value.longitude,
        )),
        Failed(:final failure) => Failed(failure),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.nearestEvacuationCenterHeading),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final position = _position;

    if (position == null) {
      return const Row(
        children: [
          LoadingSkeleton(height: 40, width: 40, borderRadius: 10),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(height: 14, width: 140),
                SizedBox(height: 8),
                LoadingSkeleton(height: 12),
              ],
            ),
          ),
        ],
      );
    }

    return switch (position) {
      Failed() => _UnavailableState(onRetry: _requestPosition),
      Success(:final value) => _NearestResult(
        latitude: value.latitude,
        longitude: value.longitude,
      ),
    };
  }
}

class _UnavailableState extends StatelessWidget {
  const _UnavailableState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.location_off_outlined,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.nearestCenterUnavailable,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                l10n.enableLocationServices,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(l10n.tryAgain),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(44, 40),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NearestResult extends ConsumerWidget {
  const _NearestResult({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final centersAsync = ref.watch(
      nearestEvacuationCentersProvider(latitude, longitude),
    );

    return switch (centersAsync) {
      AsyncData(:final value) when value.isNotEmpty => _CenterTile(
        center: value.first,
      ),
      // A resolved position with zero nearby results is a different
      // story than "couldn't get your location" — reusing
      // _UnavailableState's copy here would tell a resident to "enable
      // location services" when location worked fine and there's just
      // no data yet.
      AsyncData() => EmptyState(
        message: l10n.noNearbyEvacuationCenters,
        icon: Icons.location_searching,
      ),
      AsyncError(:final error) => ErrorState(
        message: '${l10n.couldNotLoadNearbyCenters} — $error',
        onRetry: () => ref.invalidate(
          nearestEvacuationCentersProvider(latitude, longitude),
        ),
      ),
      _ => const Row(
        children: [
          LoadingSkeleton(height: 40, width: 40, borderRadius: 10),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(height: 14, width: 140),
                SizedBox(height: 8),
                LoadingSkeleton(height: 12),
              ],
            ),
          ),
        ],
      ),
    };
  }
}

class _CenterTile extends StatelessWidget {
  const _CenterTile({required this.center});

  final EvacuationCenter center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final accent = _statusColor(
      center.status,
      center.occupancyPercent,
      semantic,
      theme,
    );
    final distance = center.distanceMeters;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.go('/nearest-center'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.home_work_outlined, color: accent, size: 20),
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
                        center.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Bounded width, same as EvacuationCenterCard's own
                    // status pill: maxLines/overflow alone don't clip
                    // anything unless the Text also has a width limit to
                    // overflow against, and this sits next to an
                    // Expanded sibling that can't be relied on to leave
                    // enough room for an arbitrarily long backend string.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          localizedCenterStatus(context, center.status),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  center.displayLocation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (distance != null) ...[
                      Icon(
                        Icons.directions_walk,
                        size: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatDistance(distance),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        l10n.viewRoute,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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

  static String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m away';
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  static Color _statusColor(
    String status,
    double? occupancyPercent,
    AppSemanticColors semantic,
    ThemeData theme,
  ) {
    if (status.toLowerCase().contains('closed') || occupancyPercent == null) {
      return theme.colorScheme.onSurfaceVariant;
    }
    if (occupancyPercent >= 95) return theme.colorScheme.error;
    if (occupancyPercent >= 75) return semantic.warning;
    return semantic.success;
  }
}
