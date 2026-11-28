import '../../core/widgets/map_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/staff_read_cache.dart';
import '../../core/utils/data_freshness_formatter.dart';
import '../../core/widgets/stat_strip.dart';
import '../../core/widgets/ui_kit.dart';
import '../../l10n/app_localizations.dart';
import '../registered_families/domain/entities/registered_family.dart';
import '../registered_families/presentation/widgets/registered_family_detail_sheet.dart';
import '../staff_shell/current_event.dart';

/// One family staying with relatives or friends (a "private house").
class PrivateHouseFamily {
  const PrivateHouseFamily({
    required this.id,
    required this.label,
    required this.memberCount,
    this.hostName,
    this.hostWhere = '',
    this.incomplete = false,
  });

  factory PrivateHouseFamily.fromJson(Map<String, dynamic> j) =>
      PrivateHouseFamily(
        id: j['id'] as int,
        label: j['label'] as String? ?? '',
        memberCount: (j['member_count'] as num?)?.toInt() ?? 0,
        hostName: j['host_name'] as String?,
        hostWhere: [
          ?((j['host_purok'] as Map<String, dynamic>?)?['name'] as String?),
          ?(j['host_address'] as String?),
        ].where((s) => s.trim().isNotEmpty).join(', '),
        incomplete: j['incomplete'] == true,
      );

  final int id;
  final String label;
  final int memberCount;
  final String? hostName;

  /// The house's purok and address, as far as they are known.
  final String hostWhere;

  /// A member still lacks a name, sex or birth date ("details pending").
  final bool incomplete;
}

/// `GET /private-house-families`: per barangay how many families and
/// persons stay in private houses, and with a barangay, the families.
class PrivateHouses {
  const PrivateHouses({
    required this.barangays,
    required this.families,
    required this.fetchedAt,
    required this.fromCache,
  });

  factory PrivateHouses.fromJson(
    Map<String, dynamic> j, {
    required DateTime fetchedAt,
    required bool fromCache,
  }) => PrivateHouses(
    barangays: {
      for (final b in j['barangays'] as List? ?? const [])
        ((b as Map<String, dynamic>)['barangay'] as Map<String, dynamic>)['id']
            as int: (
          families: (b['families'] as num?)?.toInt() ?? 0,
          persons: (b['persons'] as num?)?.toInt() ?? 0,
        ),
    },
    families: [
      for (final f in j['families'] as List? ?? const [])
        PrivateHouseFamily.fromJson(f as Map<String, dynamic>),
    ],
    fetchedAt: fetchedAt,
    fromCache: fromCache,
  );

  final Map<int, ({int families, int persons})> barangays;
  final List<PrivateHouseFamily> families;
  final DateTime fetchedAt;
  final bool fromCache;

  ({int families, int persons}) of(int barangayId) =>
      barangays[barangayId] ?? (families: 0, persons: 0);
}

/// The private houses of the selected event; with [barangayId] (an
/// official may only ask for their own), also that barangay's families.
/// Saved for offline.
final privateHousesProvider = FutureProvider.autoDispose
    .family<PrivateHouses, int?>((ref, barangayId) async {
      final event = await ref.watch(currentStaffEventProvider.future);
      final read = await ref
          .watch(staffReadCacheProvider)
          .get(
            '/private-house-families',
            query: {
              'evacuation_event_id': ?event?.id,
              'barangay_id': ?barangayId,
            },
          );
      return PrivateHouses.fromJson(
        read.data,
        fetchedAt: read.fetchedAt,
        fromCache: read.isFromCache,
      );
    });

/// A barangay's families in private houses: who, with whom, where.
/// A card opens the family.
class PrivateHousesPage extends ConsumerWidget {
  const PrivateHousesPage({super.key, required this.barangayId});

  final int barangayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(privateHousesProvider(barangayId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privateHousesTitle)),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(privateHousesProvider(barangayId)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding(context),
          children: async.when(
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (_, _) => [
              EmptyNote(
                icon: Icons.cloud_off_outlined,
                message: l10n.monitoringNeedsConnection,
              ),
            ],
            data: (d) {
              final total = d.of(barangayId);
              return [
                if (d.fromCache)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l10n.savedCopyAge(formatElapsedSince(d.fetchedAt)),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                StatStrip(
                  items: [
                    StatItem(l10n.monitoringFamilies, '${total.families}'),
                    StatItem(l10n.monitoringPersons, '${total.persons}'),
                  ],
                ),
                const SizedBox(height: 16),
                if (d.families.isEmpty)
                  EmptyNote(
                    icon: Icons.house_outlined,
                    message: l10n.privateHousesNone,
                  )
                else
                  for (final f in d.families) ...[
                    _FamilyCard(family: f, barangayId: barangayId),
                    const SizedBox(height: 8),
                  ],
              ];
            },
          ),
        ),
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({required this.family, required this.barangayId});

  final PrivateHouseFamily family;
  final int barangayId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppCard(
      onTap: () => showRegisteredFamilyDetailSheet(
        context,
        RegisteredFamily(
          id: family.id,
          barangayId: barangayId,
          barangayName: '',
          headOfFamilyName: family.label,
          memberCount: family.memberCount,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(family.label, style: theme.textTheme.titleMedium),
          Text(l10n.privateHouseWith(family.hostName ?? '')),
          if (family.hostWhere.isNotEmpty)
            Text(family.hostWhere, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.ecBoardFamilyMembers(family.memberCount),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (family.incomplete)
                SheetBadge(
                  label: l10n.privateHouseDetailsPending,
                  tone: BadgeTone.warning,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Private houses: 5 families (18 persons)", one tap from the list.
class PrivateHousesCard extends ConsumerWidget {
  const PrivateHousesCard({
    super.key,
    required this.barangayId,
    required this.onOpen,
  });

  final int barangayId;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final d = ref.watch(privateHousesProvider(null)).value;
    final total = d?.of(barangayId);
    return AppCard(
      onTap: onOpen,
      child: Row(
        children: [
          Icon(Icons.house_outlined, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.privateHousesTitle,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  total == null
                      ? l10n.privateHousesSubtitle
                      : l10n.privateHousesSummary(
                          l10n.countFamilies(total.families),
                          l10n.countPersons(total.persons),
                        ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
