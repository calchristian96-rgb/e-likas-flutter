import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/occupancy_progress.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../evacuation_centers/domain/entities/evacuation_center.dart';
import '../../../evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import '../../../evacuation_centers/presentation/widgets/center_status_display.dart';
import '../../../staff_auth/domain/entities/staff_session.dart';
import '../../../staff_auth/presentation/widgets/staff_auth_guard.dart';

/// "My Evacuation Centers" — the staff member's OWN barangay's centers,
/// straight away, as one flat list. Other barangays' centers are
/// reached through EC Board (citywide) instead, so this page never
/// lists them and needs no barangay step or "your barangay" label.
/// An administrator/CSWD account has no barangay of its own, so it
/// sees every center.
///
/// Deliberately reuses [allEvacuationCentersProvider] (the same
/// public `/public/evacuation-centers` data the resident Evacuation
/// Centers list already shows) rather than a second staff-specific
/// list endpoint: the authenticated `EvacuationCenterController::
/// index()` is a deliberately lightweight lookup (`id, name,
/// barangay_id, status` only — confirmed against the controller) built
/// for the registration form's dropdown, not for a management list
/// that needs type/address/capacity too. The public endpoint already
/// has everything this list displays, including each center's live
/// occupancy (network-first; when it falls back to the copy saved on
/// this device, an [OfflineBanner] says so and how old it is).
///
/// What it does NOT have is `created_by`, so this list can't reliably
/// show an Edit affordance per row — that's decided on
/// [StaffEvacuationCenterDetailPage] instead, which fetches the real
/// authenticated detail (including `created_by`) for the one center
/// being viewed. See `center_edit_permission.dart`.
class StaffEvacuationCentersListPage extends StatelessWidget {
  const StaffEvacuationCentersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffAuthGuard(
      builder: (context, session) =>
          _StaffEvacuationCentersListBody(session: session),
    );
  }
}

class _StaffEvacuationCentersListBody extends ConsumerStatefulWidget {
  const _StaffEvacuationCentersListBody({required this.session});

  final StaffSession session;

  @override
  ConsumerState<_StaffEvacuationCentersListBody> createState() =>
      _StaffEvacuationCentersListBodyState();
}

class _StaffEvacuationCentersListBodyState
    extends ConsumerState<_StaffEvacuationCentersListBody> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Only the staff member's own barangay — matched by name, the one
  /// field both a public-list center and a [StaffSession] reliably
  /// carry (see `pinOwnBarangayFirst`'s doc comment) — then the search
  /// query, a purely local filter (no request per keystroke).
  List<EvacuationCenter> _visibleCenters(List<EvacuationCenter> centers) {
    final ownBarangay = widget.session.barangayName;
    final own = ownBarangay == null || ownBarangay.isEmpty
        ? centers
        : centers.where((c) => c.barangay == ownBarangay).toList();
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return own;
    return own.where((center) {
      return center.name.toLowerCase().contains(query) ||
          (center.address?.toLowerCase().contains(query) ?? false) ||
          localizedCenterType(
            context,
            center.type,
          ).toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _refresh() async {
    ref.invalidate(allEvacuationCentersSnapshotProvider);
    try {
      await ref.read(allEvacuationCentersProvider.future);
    } catch (_) {
      // The error state below already handles this.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final centersAsync = ref.watch(allEvacuationCentersProvider);
    final snapshot = ref.watch(allEvacuationCentersSnapshotProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.staffManageEvacuationCenters)),
      body: Column(
        children: [
          // Whenever this is the copy saved on this device rather than a
          // live server response (offline, or the fetch failed) — the
          // occupancy figures could be out of date, so it's said plainly.
          OfflineBanner(
            isOffline: snapshot?.isFromCache ?? false,
            lastUpdated: snapshot?.lastSyncedAt,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: FilledButton.icon(
              // Always visible, regardless of the list's own load
              // state — adding a center doesn't depend on this list
              // having loaded successfully.
              onPressed: () =>
                  context.push('/settings/staff/evacuation-centers/add'),
              icon: const Icon(Icons.add_business_outlined),
              label: Text(l10n.staffAddEvacuationCenter),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchField(
              controller: _searchController,
              hintText: l10n.searchMyEvacuationCentersHint,
              clearTooltip: l10n.clearSearch,
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: centersAsync.when(
              data: (centers) {
                final visible = _visibleCenters(centers);
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: visible.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(32),
                          children: [
                            Center(
                              child: Text(
                                _searchQuery.trim().isEmpty
                                    ? l10n.noEvacuationCenters
                                    : l10n.noCentersMatchFilter,
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) =>
                              _StaffCenterTile(center: visible[index]),
                        ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: ErrorState(
                  message: l10n.couldNotLoadCenters,
                  onRetry: () =>
                      ref.invalidate(allEvacuationCentersSnapshotProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffCenterTile extends StatelessWidget {
  const _StaffCenterTile({required this.center});

  final EvacuationCenter center;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final statusColor = centerStatusColor(context, center);
    final warning =
        theme.extension<AppSemanticColors>()?.warning ?? Colors.amber.shade800;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            context.push('/settings/staff/evacuation-centers/${center.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.12),
                child: Icon(Icons.home_work_outlined, color: statusColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(center.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      center.displayLocation.isNotEmpty
                          ? center.displayLocation
                          : localizedCenterType(context, center.type),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    // Live, from the server: who's here now vs capacity —
                    // the same readout the resident center list uses.
                    if (center.hasOccupancyData) ...[
                      const SizedBox(height: 8),
                      OccupancyProgress(
                        current: center.currentOccupancy!,
                        capacity: center.capacityPersons,
                        percent: center.occupancyPercent!,
                        color: statusColor,
                      ),
                    ],
                    if (!center.hasCoordinates) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            size: 14,
                            color: warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.centerNoLocationSet,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusDot(color: statusColor),
                  const SizedBox(height: 2),
                  Text(
                    localizedCenterStatus(context, center.status),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
