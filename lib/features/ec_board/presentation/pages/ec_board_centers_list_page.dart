import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../evacuation_centers/presentation/widgets/center_status_display.dart';
import '../../../family_registration/presentation/providers/lookup_providers.dart';
import '../../../staff_auth/presentation/widgets/staff_auth_guard.dart';
import '../../../staff_evacuation_centers/presentation/providers/own_centers_provider.dart';
import '../../../staff_evacuation_centers/presentation/widgets/approval_badge.dart';

/// EC Board's center picker: the official's own barangay's centers
/// only (backend: officials see their own barangay), matched by id.
/// Unverified centers are usable and say so; rejected ones are left
/// out, since the server refuses them on the board (422).
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ecBoardTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                final usable = centers.where((c) => c.center.isUsable);
                final query = _searchQuery.trim().toLowerCase();
                final visible = [
                  for (final c in usable)
                    if (query.isEmpty || c.name.toLowerCase().contains(query))
                      c,
                ];
                if (visible.isEmpty) {
                  return Center(
                    child: Text(
                      query.isEmpty
                          ? l10n.staffOwnCentersEmpty
                          : l10n.noCentersMatchFilter,
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(evacuationCentersLookupProvider);
                    await ref.read(ownCentersProvider.future);
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) =>
                        _EcBoardCenterTile(center: visible[i]),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: ErrorState(
                  message: l10n.couldNotLoadCenters,
                  onRetry: () =>
                      ref.invalidate(evacuationCentersLookupProvider),
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

  final OwnCenter center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final public = center.public;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        minVerticalPadding: 12,
        onTap: () => context.push('/settings/staff/ec-board/${center.id}'),
        leading: Icon(
          Icons.fact_check_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(center.name),
        subtitle: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(localizedCenterStatus(context, center.center.status)),
            if (public?.hasOccupancyData ?? false)
              Text('${public!.currentOccupancy} / ${public.capacityPersons}'),
            ApprovalBadge(center: center.center),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
