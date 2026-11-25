import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/occupancy_progress.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import '../../../evacuation_centers/presentation/widgets/center_status_display.dart';
import '../../../family_registration/presentation/providers/lookup_providers.dart';
import '../../../staff_auth/presentation/widgets/staff_auth_guard.dart';
import '../providers/own_centers_provider.dart';
import '../widgets/approval_badge.dart';
import '../widgets/center_needs_details.dart';
import '../widgets/occupancy_note.dart';
import '../../../../core/widgets/ui_kit.dart';

/// "My Evacuation Centers": the official's own barangay's centers,
/// from the staff `GET /evacuation-centers` (so Unverified and rejected
/// centers are listed too, each with its badge), matched by barangay
/// id. The figures, the bar and the status are the staff list's, for the
/// selected event (backend d17f6de); the public copy is not used here
/// (it counts every open event). CSWD (no barangay of its own) sees
/// every center.
class StaffEvacuationCentersListPage extends StatelessWidget {
  const StaffEvacuationCentersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffAuthGuard(builder: (context, session) => const _Body());
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body();

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(evacuationCentersLookupProvider);
    ref.invalidate(allEvacuationCentersSnapshotProvider);
    try {
      await ref.read(ownCentersProvider.future);
    } catch (_) {
      // The error state below already handles this.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final centersAsync = ref.watch(ownCentersProvider);
    final snapshot = ref.watch(allEvacuationCentersSnapshotProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.staffManageEvacuationCenters)),
      body: Column(
        children: [
          OfflineBanner(
            isOffline: snapshot?.isFromCache ?? false,
            lastUpdated: snapshot?.lastSyncedAt,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                final query = _searchQuery.trim().toLowerCase();
                final visible = [
                  for (final c in centers)
                    if (query.isEmpty || c.name.toLowerCase().contains(query))
                      c,
                ];
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: visible.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(32),
                          children: [
                            Center(
                              child: Text(
                                query.isEmpty
                                    ? l10n.staffOwnCentersEmpty
                                    : l10n.noCentersMatchFilter,
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                  onRetry: _refresh,
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

  final OwnCenter center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = centerStatusColorOf(center.status);
    final occupancy = center.occupancy;
    final percent = center.occupancyPercent;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            context.push('/staff/more/evacuation-centers/${center.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      center.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(
                    label: localizedCenterStatus(context, center.status),
                    color: statusColor,
                  ),
                ],
              ),
              ApprovalBadge(center: center.center),
              if (center.center.isRejected &&
                  center.center.rejectionReason != null) ...[
                const SizedBox(height: 4),
                Text(
                  center.center.rejectionReason!,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (occupancy != null &&
                  percent != null &&
                  !center.isCapacityUnknown) ...[
                const SizedBox(height: 8),
                OccupancyProgress(
                  current: occupancy,
                  capacity: center.capacity!,
                  percent: percent,
                  estimated: center.isCapacityEstimated,
                  color: statusColor,
                ),
              ],
              OccupancyNote(note: center.occupancyNote),
              CenterNeedsChips(center: center),
            ],
          ),
        ),
      ),
    );
  }
}
