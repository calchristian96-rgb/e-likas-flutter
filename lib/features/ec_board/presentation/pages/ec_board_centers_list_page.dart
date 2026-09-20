import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../evacuation_centers/domain/entities/evacuation_center.dart';
import '../../../evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import '../../../evacuation_centers/presentation/widgets/center_status_display.dart';
import '../../../evacuation_centers/presentation/widgets/pin_own_barangay_first.dart';
import '../../../staff_auth/domain/entities/staff_session.dart';
import '../../../staff_auth/presentation/widgets/staff_auth_guard.dart';

/// EC Board's own top-level entry point — a dedicated barangay-pinned
/// center picker reached straight from the Staff Workspace, so opening
/// the board no longer requires a detour through "My Evacuation
/// Centers" management first. Deliberately a separate page from
/// [StaffEvacuationCentersListPage] rather than a shared one: that
/// page's "Add a center" action and edit-permission framing belong to
/// center *management*, which has nothing to do with why someone
/// opens EC Board (to record evacuees), even though both screens list
/// the same centers the same barangay-pinned way.
class EcBoardCentersListPage extends StatelessWidget {
  const EcBoardCentersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffAuthGuard(
      builder: (context, session) =>
          _EcBoardCentersListBody(session: session),
    );
  }
}

class _EcBoardCentersListBody extends ConsumerStatefulWidget {
  const _EcBoardCentersListBody({required this.session});

  final StaffSession session;

  @override
  ConsumerState<_EcBoardCentersListBody> createState() =>
      _EcBoardCentersListBodyState();
}

class _EcBoardCentersListBodyState
    extends ConsumerState<_EcBoardCentersListBody> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EvacuationCenter> _visibleCenters(List<EvacuationCenter> centers) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return centers;
    return centers.where((center) {
      return center.name.toLowerCase().contains(query) ||
          (center.barangay?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final centersAsync = ref.watch(allEvacuationCentersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ecBoardTitle)),
      body: Column(
        children: [
          if (widget.session.isBarangayOfficial)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                l10n.staffCentersCitywideNotice,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchField(
              controller: _searchController,
              hintText: l10n.searchCentersHint,
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
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: buildBarangayGroupedCenterTiles(
                    centers: visible,
                    ownBarangayName: widget.session.barangayName,
                    ownGroupLabel: l10n.centersYourBarangaySection,
                    othersGroupLabel: l10n.centersOtherBarangaysSection,
                    tileBuilder: (center) => _EcBoardCenterTile(
                      center: center,
                    ),
                    spacer: const SizedBox(height: 8),
                  ),
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

class _EcBoardCenterTile extends StatelessWidget {
  const _EcBoardCenterTile({required this.center});

  final EvacuationCenter center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = centerStatusColor(context, center);

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () =>
            context.push('/settings/staff/ec-board/${center.id}'),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          child: Icon(Icons.fact_check_outlined, color: statusColor),
        ),
        title: Text(center.name),
        subtitle: Text(
          center.displayLocation.isNotEmpty
              ? center.displayLocation
              : localizedCenterType(context, center.type),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          localizedCenterStatus(context, center.status),
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}
