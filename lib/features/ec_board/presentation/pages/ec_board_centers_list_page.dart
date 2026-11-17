import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../core/widgets/stat_strip.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../box_relief/relief_page.dart';
import '../../../evacuation_centers/presentation/widgets/center_status_display.dart';
import '../../../family_registration/presentation/providers/lookup_providers.dart';
import '../../../staff_auth/presentation/widgets/staff_auth_guard.dart';
import '../../../staff_evacuation_centers/presentation/providers/own_centers_provider.dart';
import '../../../staff_evacuation_centers/presentation/widgets/approval_badge.dart';

/// The EC Information Board's center list (Part 3.4): a short summary
/// first (centers, evacuees, boxes left), then one card per own center
/// with occupancy / capacity (e.g. 48 / 120) and its status chip. A card
/// opens that center's board (check in, check out). Rejected centers are
/// left out: the server refuses them on the board.
class EcBoardCentersListPage extends StatelessWidget {
  const EcBoardCentersListPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final centersAsync = ref.watch(ownCentersProvider);
    final round = ref.watch(barangayBoxesProvider).value?.boxes.latestRound;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ecBoardTitle)),
      body: centersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: ErrorState(
            message: l10n.couldNotLoadCenters,
            onRetry: () => ref.invalidate(evacuationCentersLookupProvider),
          ),
        ),
        data: (centers) {
          final usable = [
            for (final c in centers)
              if (c.center.isUsable) c,
          ];
          final evacuees = usable.fold<int>(
            0,
            (sum, c) => sum + (c.public?.currentOccupancy ?? 0),
          );
          final query = _searchQuery.trim().toLowerCase();
          final visible = [
            for (final c in usable)
              if (query.isEmpty || c.name.toLowerCase().contains(query)) c,
          ];
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(evacuationCentersLookupProvider);
              ref.invalidate(barangayBoxesProvider);
              await ref.read(ownCentersProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: pagePadding(context),
              children: [
                StatStrip(
                  items: [
                    StatItem(l10n.monitoringCenters, '${usable.length}'),
                    StatItem(l10n.homeEvacuees, '$evacuees'),
                    StatItem(
                      l10n.homeBoxesLeft,
                      round == null ? '–' : '${round.figures.leftToGive}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (usable.length > 5) ...[
                  SearchField(
                    controller: _searchController,
                    hintText: l10n.searchCentersHint,
                    clearTooltip: l10n.clearSearch,
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 16),
                ],
                if (visible.isEmpty)
                  EmptyNote(
                    icon: Icons.home_work_outlined,
                    message: query.isEmpty
                        ? l10n.staffOwnCentersEmpty
                        : l10n.noCentersMatchFilter,
                  )
                else
                  for (final c in visible) ...[
                    _CenterCard(center: c),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CenterCard extends StatelessWidget {
  const _CenterCard({required this.center});

  final OwnCenter center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final public = center.public;
    final status = center.center.status;
    final occupancy = public?.currentOccupancy;
    final capacity = public?.capacityPersons;
    return AppCard(
      onTap: () => context.push('/staff/centers/${center.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(center.name, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  occupancy == null
                      ? l10n.homeNoOccupancyYet
                      : (capacity ?? 0) > 0
                      ? '$occupancy / $capacity'
                      : l10n.monitoringInsideNoCapacity(occupancy),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              StatusChip(
                label: localizedCenterStatus(context, status),
                color: centerStatusColorOf(status),
              ),
            ],
          ),
          if (!center.center.isApproved || center.center.hasPendingChange) ...[
            const SizedBox(height: 8),
            ApprovalBadge(center: center.center),
          ],
        ],
      ),
    );
  }
}
