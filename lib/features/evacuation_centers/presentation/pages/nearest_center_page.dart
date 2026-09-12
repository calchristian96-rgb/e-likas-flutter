import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/widgets/center_summary_row.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/evacuation_centers_provider.dart';
import '../widgets/evacuation_center_card.dart';

class NearestCenterPage extends ConsumerStatefulWidget {
  const NearestCenterPage({super.key});

  @override
  ConsumerState<NearestCenterPage> createState() => _NearestCenterPageState();
}

class _NearestCenterPageState extends ConsumerState<NearestCenterPage> {
  Result<({double latitude, double longitude})>? _position;

  @override
  void initState() {
    super.initState();
    _requestPosition();
  }

  /// One-shot GPS read, same as before — never continuous tracking.
  /// Reused both for the initial load and as "Refresh Location"
  /// (button and pull-to-refresh) below, so there's exactly one
  /// location-fetching code path in this screen.
  Future<void> _requestPosition() async {
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
    final position = _position;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.nearestCenterTitle),
        actions: [
          IconButton(
            tooltip: l10n.viewAllEvacuationCenters,
            icon: const Icon(Icons.list_alt_outlined),
            onPressed: () => context.push('/centers'),
          ),
        ],
      ),
      body: switch (position) {
        null => const Center(child: CircularProgressIndicator()),
        Failed(:final failure) => _LocationError(
          failure: failure,
          onRetry: _requestPosition,
        ),
        Success(:final value) => _NearestCentersBody(
          latitude: value.latitude,
          longitude: value.longitude,
          onRefreshLocation: _requestPosition,
        ),
      },
    );
  }
}

class _NearestCentersBody extends ConsumerWidget {
  const _NearestCentersBody({
    required this.latitude,
    required this.longitude,
    required this.onRefreshLocation,
  });

  final double latitude;
  final double longitude;
  final Future<void> Function() onRefreshLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final centersAsync = ref.watch(
      nearestEvacuationCentersProvider(latitude, longitude),
    );

    return centersAsync.when(
      data: (centers) {
        if (centers.isEmpty) {
          return _CenteredScrollable(
            child: EmptyState(
              message: l10n.noNearbyEvacuationCenters,
              icon: Icons.location_searching,
            ),
          );
        }

        // The `/nearest` endpoint already returns up to `limit` centers
        // in one request — the first is the primary result, the rest
        // are shown below as "Other nearby centers". No per-row request:
        // both sections come from this single already-loaded list.
        final primary = centers.first;
        final others = centers.length > 1 ? centers.sublist(1) : const [];

        return RefreshIndicator(
          onRefresh: () async {
            await onRefreshLocation();
            ref.invalidate(
              nearestEvacuationCentersProvider(latitude, longitude),
            );
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                l10n.nearestEvacuationCenterHeading,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              // Reuses EvacuationCenterCard rather than a second,
              // near-identical "primary card" widget — it already
              // shows every real field asked for here (name, address,
              // status, occupancy, distance) plus Get Directions.
              EvacuationCenterCard(center: primary),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/map'),
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: Text(l10n.viewOnMap),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRefreshLocation,
                        icon: const Icon(Icons.my_location, size: 18),
                        label: Text(l10n.refreshLocation),
                      ),
                    ),
                  ],
                ),
              ),
              if (others.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    l10n.otherNearbyCenters,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      for (var i = 0; i < others.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            color: theme.colorScheme.outlineVariant,
                          ),
                        CenterSummaryRow(
                          center: others[i],
                          onTap: () => context.push('/centers/${others[i].id}'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _CenteredScrollable(
        child: ErrorState(
          message: '${l10n.couldNotLoadNearbyCenters} — $error',
          onRetry: () => ref.invalidate(
            nearestEvacuationCentersProvider(latitude, longitude),
          ),
        ),
      ),
    );
  }
}

class _LocationError extends StatelessWidget {
  const _LocationError({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Retrying the in-app permission request can't work once Android has
    // permanently denied it — only System Settings can undo that, so
    // that's the only case this offers a second action for.
    final permanentlyDenied = switch (failure) {
      LocationFailure(:final permanentlyDenied) => permanentlyDenied,
      _ => false,
    };
    final reason = switch (failure) {
      LocationFailure(:final reason) => reason,
      _ => null,
    };

    return _CenteredScrollable(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ErrorState(
            message: _localizedMessage(reason, l10n) ?? failure.message,
            icon: Icons.location_off_outlined,
            onRetry: onRetry,
          ),
          if (permanentlyDenied)
            TextButton.icon(
              onPressed: () => Geolocator.openAppSettings(),
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: Text(l10n.openSettings),
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            ),
        ],
      ),
    );
  }

  /// Prefers the classified [LocationFailureReason] (localized) over
  /// [Failure.message] (English-only, set from a service with no
  /// [BuildContext] to localize from) — see [LocationFailureReason]'s
  /// own doc comment. Returns null only if [reason] is itself null
  /// (not a [LocationFailure], shouldn't happen here in practice), in
  /// which case the caller falls back to the raw message.
  static String? _localizedMessage(
    LocationFailureReason? reason,
    AppLocalizations l10n,
  ) {
    return switch (reason) {
      LocationFailureReason.servicesDisabled => l10n.locationServicesOff,
      LocationFailureReason.permissionDenied => l10n.locationPermissionDenied,
      LocationFailureReason.permanentlyDenied => l10n.locationPermanentlyDenied,
      LocationFailureReason.positionUnavailable =>
        l10n.couldNotDetermineLocation,
      null => null,
    };
  }
}

/// Same reasoning as every other list screen's equivalent —
/// `RefreshIndicator`/centering needs a scrollable descendant to work
/// at all, even when there's nothing (or just an error) to show.
class _CenteredScrollable extends StatelessWidget {
  const _CenteredScrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
          ),
        );
      },
    );
  }
}
