import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/center_summary_row.dart';
import '../../../l10n/app_localizations.dart';
import '../../evacuation_centers/domain/entities/evacuation_center.dart';
import '../../evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import 'barangay_status_providers.dart';

/// The approved centers of the resident's own barangay, matched by
/// `barangay_id` (never by name), by name. Includes centers with no map
/// location yet, which no distance ranking can show: most centers have
/// none today (backend map-api.md).
final ownBarangayCentersProvider =
    FutureProvider.autoDispose<List<EvacuationCenter>>((ref) async {
      final own = ref.watch(residentBarangayProvider);
      if (own == null) return const [];
      final centers = await ref.watch(allEvacuationCentersProvider.future);
      return [
        for (final c in centers)
          if (c.barangayId == own.id) c,
      ]..sort((a, b) => a.name.compareTo(b.name));
    });

/// "Centers in Brgy. X": the fallback when the GPS is off or a center
/// has no location, so a resident always has somewhere to go.
class OwnBarangayCentersSection extends ConsumerWidget {
  const OwnBarangayCentersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final own = ref.watch(residentBarangayProvider);
    final centers = ref.watch(ownBarangayCentersProvider).value;
    if (own == null || centers == null || centers.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          l10n.centersInYourBarangay(own.name),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                for (var i = 0; i < centers.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  CenterSummaryRow(
                    center: centers[i],
                    onTap: () => context.push('/centers/${centers[i].id}'),
                  ),
                  if (!centers[i].hasCoordinates)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                      child: Text(
                        l10n.centerNoMapLocationYet,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
