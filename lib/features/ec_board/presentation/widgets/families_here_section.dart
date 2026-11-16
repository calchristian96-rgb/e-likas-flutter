import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../registered_families/domain/entities/registered_family.dart';
import '../../../registered_families/presentation/widgets/registered_family_detail_sheet.dart';
import '../../domain/entities/family_here.dart';
import '../providers/ec_board_provider.dart';

/// The families with someone at this center now (C17), so check-out is
/// done where the official already is: a row opens the family, whose
/// "Mark family as departed" checks people out (queued when the
/// connection drops). Shows the first rows, then "Show all".
class FamiliesHereSection extends ConsumerStatefulWidget {
  const FamiliesHereSection({
    super.key,
    required this.centerId,
    required this.evacuationEventId,
  });

  final int centerId;
  final int evacuationEventId;

  @override
  ConsumerState<FamiliesHereSection> createState() =>
      _FamiliesHereSectionState();
}

class _FamiliesHereSectionState extends ConsumerState<FamiliesHereSection> {
  static const _firstRows = 10;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(
      ecBoardFamiliesHereProvider(widget.centerId, widget.evacuationEventId),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.ecBoardFamiliesHereTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Text(
            l10n.ecBoardFamiliesHereOffline,
            style: theme.textTheme.bodyMedium,
          ),
          data: (families) {
            if (families.isEmpty) {
              return Text(
                l10n.ecBoardFamiliesHereEmpty,
                style: theme.textTheme.bodyMedium,
              );
            }
            final shown = _showAll
                ? families
                : families.take(_firstRows).toList();
            return Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < shown.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _FamilyRow(family: shown[i]),
                  ],
                  if (!_showAll && families.length > _firstRows)
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () => setState(() => _showAll = true),
                      child: Text(l10n.showAllCount(families.length)),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FamilyRow extends StatelessWidget {
  const _FamilyRow({required this.family});

  final FamilyHere family;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = family.isGeneric || family.name == null
        ? l10n.ecBoardFamilyNumber(family.id)
        : family.name!;
    final details = [
      ?family.barangayName,
      ?family.purokName,
      l10n.ecBoardFamilyMembers(family.memberCount),
    ].join(' · ');
    return ListTile(
      minTileHeight: 56,
      title: Text(name),
      subtitle: Text(details),
      trailing: const Icon(Icons.chevron_right),
      // Another barangay's family is shown by number only and is not
      // ours to check out.
      onTap: family.isGeneric
          ? null
          : () => showRegisteredFamilyDetailSheet(
              context,
              RegisteredFamily(
                id: family.id,
                barangayId: null,
                barangayName: family.barangayName ?? '',
                headOfFamilyName: name,
                memberCount: family.memberCount,
                hasHeadLinked: family.headLinked,
              ),
            ),
    );
  }
}
