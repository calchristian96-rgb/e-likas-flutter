import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/sync_now_action.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../family_registration/domain/entities/lookup_entities.dart';
import '../../../family_registration/domain/entities/pending_registration_status.dart';
import '../../../family_registration/presentation/providers/lookup_providers.dart';
import '../../../family_registration/presentation/providers/pending_queue_provider.dart';
import '../../domain/entities/age_bracket.dart';
import '../../domain/entities/pending_ec_board_entry.dart';
import '../providers/ec_board_provider.dart';
import 'add_evacuee_form_page.dart'
    show AddEvacueeFormPage, localizedAgeBracket, localizedSectoralGroup;
import 'pending_ec_entry_detail_page.dart';

/// EC Information Board for one center — reached from
/// `StaffEvacuationCenterDetailPage`. Shows two deliberately separate
/// breakdowns (see the task this was built against): the live,
/// server-computed "last known" snapshot of *synced* evacuees, and
/// this device's own still-pending Add Evacuee entries — never merged
/// into one number, since the pending side isn't confirmed data yet.
class EcBoardPage extends ConsumerStatefulWidget {
  const EcBoardPage({super.key, required this.centerId});

  final int centerId;

  @override
  ConsumerState<EcBoardPage> createState() => _EcBoardPageState();
}

class _EcBoardPageState extends ConsumerState<EcBoardPage> {
  int? _selectedEventId;
  bool _syncing = false;

  void _ensureEventSelected(List<EvacuationEventLookup> events) {
    if (_selectedEventId != null) return;
    final open = events.where((e) => e.isOpen).toList();
    if (open.isNotEmpty) {
      _selectedEventId = open.first.id;
    } else if (events.isNotEmpty) {
      _selectedEventId = events.first.id;
    }
  }

  Future<void> _syncNow() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _syncing = true);
    final result = await ref.read(staffSyncNowProvider)();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.stoppedForAuth
              ? l10n.staffSyncStoppedForAuthMessage
              : l10n.staffSyncCompletedMessage(result.processed),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final eventsAsync = ref.watch(evacuationEventsLookupProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ecBoardTitle),
        actions: [SyncNowAction(isSyncing: _syncing, onSync: _syncNow)],
      ),
      body: eventsAsync.when(
        data: (events) {
          _ensureEventSelected(events);
          final eventId = _selectedEventId;
          if (eventId == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyState(message: l10n.ecBoardNoEventsAvailable),
              ),
            );
          }
          return _EcBoardBody(
            centerId: widget.centerId,
            events: events,
            selectedEventId: eventId,
            onEventChanged: (id) => setState(() => _selectedEventId = id),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorState(
              message: l10n.staffRegLookupUnavailable,
              onRetry: () => ref.invalidate(evacuationEventsLookupProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _EcBoardBody extends ConsumerWidget {
  const _EcBoardBody({
    required this.centerId,
    required this.events,
    required this.selectedEventId,
    required this.onEventChanged,
  });

  final int centerId;
  final List<EvacuationEventLookup> events;
  final int selectedEventId;
  final ValueChanged<int> onEventChanged;

  Future<void> _openAddEvacuee(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AddEvacueeFormPage(
          centerId: centerId,
          evacuationEventId: selectedEventId,
        ),
      ),
    );
    ref.invalidate(ecBoardEntriesForCenterProvider(centerId));
    ref.invalidate(ecBoardCountsForCenterProvider(centerId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(ecBoardEntriesForCenterProvider(centerId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ecBoardQuickCountProvider(centerId, selectedEventId));
        ref.invalidate(ecBoardEntriesForCenterProvider(centerId));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _EventSelector(
            events: events,
            value: selectedEventId,
            onChanged: onEventChanged,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _openAddEvacuee(context, ref),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: Text(l10n.ecBoardAddEvacueeTitle),
          ),
          const Divider(height: 32),
          Text(
            l10n.ecBoardLastKnownSectionTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.ecBoardLastKnownSectionSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          _QuickCountSection(
            centerId: centerId,
            evacuationEventId: selectedEventId,
          ),
          const Divider(height: 32),
          Text(
            l10n.ecBoardPendingSectionTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.ecBoardPendingSectionSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          entriesAsync.when(
            // Scoped to the selected event, matching the live
            // breakdown above exactly — the full list further down
            // still shows every pending entry for this center,
            // regardless of event, since managing/deleting an entry
            // isn't event-dependent.
            data: (entries) => _PendingBreakdown(
              entries: entries
                  .where((e) => e.evacuationEventId == selectedEventId)
                  .toList(),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (error, stackTrace) => ErrorState(
              message: l10n.staffPendingListError,
              onRetry: () =>
                  ref.invalidate(ecBoardEntriesForCenterProvider(centerId)),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.ecBoardPendingListTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          entriesAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: EmptyState(message: l10n.ecBoardPendingListEmpty),
                );
              }
              return Column(
                children: [
                  for (final entry in entries)
                    _PendingEntryTile(centerId: centerId, entry: entry),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _EventSelector extends StatelessWidget {
  const _EventSelector({
    required this.events,
    required this.value,
    required this.onChanged,
  });

  final List<EvacuationEventLookup> events;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final openEvents = events.where((e) => e.isOpen).toList();
    // Falls back to every event only when none are open — same
    // fallback `_ensureEventSelected` already applies to the *default*
    // selection, so a center with no currently-open event still has
    // something selectable rather than an empty dropdown.
    final selectable = openEvents.isNotEmpty ? openEvents : events;
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.staffRegFieldEvacuationEvent,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final event in selectable)
          DropdownMenuItem(
            value: event.id,
            child: Text(
              event.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (id) {
        if (id != null) onChanged(id);
      },
    );
  }
}

class _QuickCountSection extends ConsumerWidget {
  const _QuickCountSection({
    required this.centerId,
    required this.evacuationEventId,
  });

  final int centerId;
  final int evacuationEventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final countAsync = ref.watch(
      ecBoardQuickCountProvider(centerId, evacuationEventId),
    );

    return countAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, stackTrace) => ErrorState(
        message: l10n.ecBoardLastKnownUnavailable,
        onRetry: () => ref.invalidate(
          ecBoardQuickCountProvider(centerId, evacuationEventId),
        ),
      ),
      data: (count) {
        if (count.ageGroups.isEmpty) {
          return EmptyState(message: l10n.ecBoardLastKnownEmpty);
        }
        return Column(
          children: [
            for (final group in count.ageGroups)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.ageBracket == null
                            ? l10n.ecBoardUnclassifiedLabel
                            : localizedAgeBracket(context, group.ageBracket!),
                      ),
                    ),
                    Text(
                      l10n.ecBoardMaleFemaleCount(
                        group.maleCount,
                        group.femaleCount,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.ecBoardTotalLabel,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  l10n.ecBoardMaleFemaleCount(
                    count.totalMale,
                    count.totalFemale,
                  ),
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            if (count.sectoralGroups.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                l10n.ecBoardSectoralGroupsSectionTitle,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.ecBoardSectoralGroupsSectionSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              for (final group in count.sectoralGroups)
                if (group.group != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            localizedSectoralGroup(context, group.group!),
                          ),
                        ),
                        Text(
                          l10n.ecBoardMaleFemaleCount(
                            group.maleCount,
                            group.femaleCount,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ],
        );
      },
    );
  }
}

class _PendingBreakdown extends StatelessWidget {
  const _PendingBreakdown({required this.entries});

  final List<PendingEcBoardEntrySummary> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return EmptyState(message: l10n.ecBoardPendingListEmpty);
    }

    final counts = <AgeBracket?, ({int male, int female})>{};
    for (final entry in entries) {
      final current = counts[entry.ageBracket] ?? (male: 0, female: 0);
      counts[entry.ageBracket] = entry.sex == 'female'
          ? (male: current.male, female: current.female + 1)
          : (male: current.male + 1, female: current.female);
    }

    var totalMale = 0;
    var totalFemale = 0;
    for (final c in counts.values) {
      totalMale += c.male;
      totalFemale += c.female;
    }

    return Column(
      children: [
        // `null` last — an unclassified local entry is the unlikely
        // corrupted-data edge case, not a normal bracket, so it's kept
        // out of the youngest-to-oldest ordering the real brackets use.
        for (final bracket in [...ageBracketValues, null])
          if (counts[bracket] case final c?)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      bracket == null
                          ? l10n.ecBoardUnclassifiedLabel
                          : localizedAgeBracket(context, bracket),
                    ),
                  ),
                  Text(
                    l10n.ecBoardMaleFemaleCount(c.male, c.female),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        const Divider(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.ecBoardTotalLabel,
                style: theme.textTheme.titleSmall,
              ),
            ),
            Text(
              l10n.ecBoardMaleFemaleCount(totalMale, totalFemale),
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _PendingEntryTile extends ConsumerWidget {
  const _PendingEntryTile({required this.centerId, required this.entry});

  final int centerId;
  final PendingEcBoardEntrySummary entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final sexLabel = entry.sex == 'female'
        ? l10n.staffRegSexFemale
        : l10n.staffRegSexMale;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => PendingEcEntryDetailPage(localId: entry.localId),
            ),
          );
          ref.invalidate(ecBoardEntriesForCenterProvider(centerId));
          ref.invalidate(ecBoardCountsForCenterProvider(centerId));
        },
        leading: switch (entry.status) {
          PendingRegistrationStatus.needsAttention => Icon(
            Icons.error_outline,
            color: colorScheme.error,
          ),
          PendingRegistrationStatus.syncing => SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          PendingRegistrationStatus.pending => Icon(
            Icons.cloud_off_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
        },
        title: Text(entry.householdLabel),
        subtitle: Text(
          '$sexLabel • ${entry.ageBracket == null ? l10n.ecBoardUnclassifiedLabel : localizedAgeBracket(context, entry.ageBracket!)}',
        ),
      ),
    );
  }
}
