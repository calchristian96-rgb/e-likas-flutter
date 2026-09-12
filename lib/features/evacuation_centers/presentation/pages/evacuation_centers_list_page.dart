import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/filter_chip_row.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/evacuation_center.dart';
import '../providers/evacuation_centers_provider.dart';
import '../widgets/center_status_display.dart';
import '../widgets/evacuation_center_card.dart';

enum _CenterSort { name, occupancy, capacity }

/// Real backend status values only ([EvacuationCenter.status], from the
/// `evacuation_centers` migration — active/full/closed/on_standby) —
/// deliberately not the reference design's "Available/Near Capacity"
/// wording, since "near capacity" is a derived occupancy-percentage
/// concept the backend doesn't tag centers with, not a real status a
/// filter chip can honestly claim to select on. Each chip uses the same
/// [localizedCenterStatus] label the card itself shows, so a resident
/// never sees the filter call something "Available" that the card then
/// calls "Active".
const _statusFilters = <String?>[
  null,
  'active',
  'full',
  'on_standby',
  'closed',
];

class EvacuationCentersListPage extends ConsumerStatefulWidget {
  const EvacuationCentersListPage({super.key});

  @override
  ConsumerState<EvacuationCentersListPage> createState() =>
      _EvacuationCentersListPageState();
}

class _EvacuationCentersListPageState
    extends ConsumerState<EvacuationCentersListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _statusFilter;
  _CenterSort _sort = _CenterSort.name;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EvacuationCenter> _visibleCenters(List<EvacuationCenter> centers) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = centers.where((center) {
      if (_statusFilter != null &&
          center.status.toLowerCase() != _statusFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return center.name.toLowerCase().contains(query) ||
          (center.address?.toLowerCase().contains(query) ?? false) ||
          (center.barangay?.toLowerCase().contains(query) ?? false);
    }).toList();

    filtered.sort((a, b) {
      return switch (_sort) {
        _CenterSort.name => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
        // Highest occupancy first — the centers most worth a second
        // look. Centers with no occupancy data (the `/nearest` shape
        // never applies here, but a defensive-parsed cache row could
        // still lack it) sort last regardless.
        _CenterSort.occupancy => _compareNullableDesc(
          a.occupancyPercent,
          b.occupancyPercent,
        ),
        _CenterSort.capacity => b.capacityPersons.compareTo(a.capacityPersons),
      };
    });
    return filtered;
  }

  static int _compareNullableDesc(double? a, double? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }

  String _countLabel(BuildContext context, List<EvacuationCenter> visible) {
    final l10n = AppLocalizations.of(context);
    final status = _statusFilter;
    if (status == null) return l10n.evacuationCentersCount(visible.length);
    return l10n.filteredCentersCount(
      visible.length,
      localizedCenterStatus(context, status),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final centersAsync = ref.watch(allEvacuationCentersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.evacuationCentersTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.evacuationCentersSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SearchField(
                        controller: _searchController,
                        hintText: l10n.searchCentersHint,
                        clearTooltip: l10n.clearSearch,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CenterSortButton(
                      sort: _sort,
                      l10n: l10n,
                      onChanged: (sort) => setState(() => _sort = sort),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilterChipRow<String?>(
                  options: _statusFilters,
                  selected: _statusFilter,
                  labelBuilder: (status) => status == null
                      ? l10n.filterAll
                      : localizedCenterStatus(context, status),
                  onSelected: (status) =>
                      setState(() => _statusFilter = status),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(allEvacuationCentersProvider.future),
              child: centersAsync.when(
                data: (centers) {
                  if (centers.isEmpty) {
                    return _CenteredInScrollView(
                      child: EmptyState(
                        message: l10n.noEvacuationCenters,
                        icon: Icons.home_work_outlined,
                      ),
                    );
                  }
                  final visible = _visibleCenters(centers);
                  if (visible.isEmpty) {
                    return _CenteredInScrollView(
                      child: EmptyState(
                        message: l10n.noCentersMatchFilter,
                        icon: Icons.search_off,
                      ),
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: visible.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                          child: Text(
                            _countLabel(context, visible),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                      return EvacuationCenterCard(center: visible[index - 1]);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _CenteredInScrollView(
                  child: ErrorState(
                    message: '${l10n.couldNotLoadCenters} — $error',
                    onRetry: () => ref.invalidate(allEvacuationCentersProvider),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterSortButton extends StatelessWidget {
  const _CenterSortButton({
    required this.sort,
    required this.onChanged,
    required this.l10n,
  });

  final _CenterSort sort;
  final ValueChanged<_CenterSort> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: PopupMenuButton<_CenterSort>(
        initialValue: sort,
        onSelected: onChanged,
        tooltip: l10n.sortCentersTooltip,
        icon: Icon(Icons.sort, color: theme.colorScheme.onSurfaceVariant),
        itemBuilder: (context) => [
          CheckedPopupMenuItem(
            value: _CenterSort.name,
            checked: sort == _CenterSort.name,
            child: Text(l10n.sortByName),
          ),
          CheckedPopupMenuItem(
            value: _CenterSort.occupancy,
            checked: sort == _CenterSort.occupancy,
            child: Text(l10n.sortByOccupancy),
          ),
          CheckedPopupMenuItem(
            value: _CenterSort.capacity,
            checked: sort == _CenterSort.capacity,
            child: Text(l10n.sortByCapacity),
          ),
        ],
      ),
    );
  }
}

/// Centers [child] within a scrollable area that still supports
/// pull-to-refresh even when there's nothing (or nothing but an
/// error) to show — `RefreshIndicator` needs a scrollable descendant
/// to work at all, so a bare `Center` isn't enough on its own here.
class _CenteredInScrollView extends StatelessWidget {
  const _CenteredInScrollView({required this.child});

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
