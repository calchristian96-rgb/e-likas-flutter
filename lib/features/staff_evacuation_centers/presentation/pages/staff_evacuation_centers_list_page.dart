import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../evacuation_centers/domain/entities/evacuation_center.dart';
import '../../../evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import '../../../evacuation_centers/presentation/widgets/center_status_display.dart';
import '../../../staff_auth/domain/entities/staff_session.dart';
import '../../../staff_auth/presentation/widgets/staff_auth_guard.dart';

/// "Manage Evacuation Centers" — the staff center-management list.
///
/// Deliberately reuses [allEvacuationCentersProvider] (the same
/// public `/public/evacuation-centers` data the resident Evacuation
/// Centers list already shows) rather than a second staff-specific
/// list endpoint: the authenticated `EvacuationCenterController::
/// index()` is a deliberately lightweight lookup (`id, name,
/// barangay_id, status` only — confirmed against the controller) built
/// for the registration form's dropdown, not for a management list
/// that needs type/address/capacity too. The public endpoint already
/// has everything this list displays.
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

  /// Filters whatever this page already legitimately received from
  /// [allEvacuationCentersProvider] — the same list the page always
  /// showed, never a broader or narrower one. A purely local,
  /// presentation-layer filter: no request is made per keystroke, and
  /// [centers] itself is never mutated, so clearing the query restores
  /// every center immediately.
  List<EvacuationCenter> _visibleCenters(List<EvacuationCenter> centers) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return centers;
    return centers.where((center) {
      return center.name.toLowerCase().contains(query) ||
          (center.address?.toLowerCase().contains(query) ?? false) ||
          (center.barangay?.toLowerCase().contains(query) ?? false) ||
          localizedCenterType(
            context,
            center.type,
          ).toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final centersAsync = ref.watch(allEvacuationCentersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.staffManageEvacuationCenters)),
      body: Column(
        children: [
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
          if (widget.session.isBarangayOfficial)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.staffCentersCitywideNotice,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
                if (centers.isEmpty) {
                  return Center(child: Text(l10n.noEvacuationCenters));
                }
                final visible = _visibleCenters(centers);
                if (visible.isEmpty) {
                  return Center(child: Text(l10n.noCentersMatchFilter));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: visible.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _StaffCenterTile(center: visible[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: ErrorState(
                  message: l10n.couldNotLoadCenters,
                  onRetry: () => ref.invalidate(allEvacuationCentersProvider),
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

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () =>
            context.push('/settings/staff/evacuation-centers/${center.id}'),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          child: Icon(Icons.home_work_outlined, color: statusColor),
        ),
        title: Text(center.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              center.displayLocation.isNotEmpty
                  ? center.displayLocation
                  : localizedCenterType(context, center.type),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!center.hasCoordinates) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 14,
                    color:
                        theme.extension<AppSemanticColors>()?.warning ??
                        Colors.amber.shade800,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.centerNoLocationSet,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.extension<AppSemanticColors>()?.warning ??
                          Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        isThreeLine: !center.hasCoordinates,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
