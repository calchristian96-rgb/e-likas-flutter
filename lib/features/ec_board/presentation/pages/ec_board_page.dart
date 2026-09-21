import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/last_updated_label.dart';
import '../../../../core/widgets/sync_now_action.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../family_registration/data/services/staff_sync_service.dart'
    show StaffSyncRunResult;
import '../../../family_registration/domain/entities/lookup_entities.dart';
import '../../../family_registration/domain/entities/pending_registration_status.dart';
import '../../../family_registration/presentation/providers/lookup_providers.dart';
import '../../../family_registration/presentation/providers/pending_queue_provider.dart';
import '../../../home/presentation/providers/home_provider.dart'
    show connectivityStatusProvider;
import '../../domain/entities/age_bracket.dart';
import '../../domain/entities/pending_ec_board_entry.dart';
import '../../domain/entities/pending_quick_count_edit.dart';
import '../providers/ec_board_provider.dart';
import 'add_evacuee_form_page.dart'
    show AddEvacueeFormPage, localizedAgeBracket, localizedSectoralGroup;
import 'pending_ec_entry_detail_page.dart';
import 'quick_departure_form_page.dart';
import 'sectoral_quick_count_form_page.dart';

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

/// Which queue a Sync Now tap is pushing — [all] is the AppBar's own
/// action (used by no other page besides this one and Pending
/// Registrations); the other two are EC Board's own contextual
/// buttons, each scoped to exactly the pending data sitting next to
/// it. `StaffSyncService._running` already guarantees only one sync of
/// any kind runs app-wide at once, so this only needs to track *which*
/// button should show its own spinner rather than all three lighting
/// up for a sync only one of them started.
enum _SyncTarget { all, ecBoardEntries, quickCountEdit }

class _EcBoardPageState extends ConsumerState<EcBoardPage> {
  int? _selectedEventId;
  _SyncTarget? _activeSync;

  void _ensureEventSelected(List<EvacuationEventLookup> events) {
    if (_selectedEventId != null) return;
    final open = events.where((e) => e.isOpen).toList();
    if (open.isNotEmpty) {
      _selectedEventId = open.first.id;
    } else if (events.isNotEmpty) {
      _selectedEventId = events.first.id;
    }
  }

  Future<void> _runSync(
    _SyncTarget target,
    Future<StaffSyncRunResult> Function() action,
  ) async {
    if (_activeSync != null) return;
    setState(() => _activeSync = target);
    final result = await action();
    if (!mounted) return;
    setState(() => _activeSync = null);
    final l10n = AppLocalizations.of(context);
    // `wasOffline` checked first — a plain count-based message would
    // otherwise read as "0 registrations synced," which looks like a
    // normal empty run rather than "this never even attempted to
    // reach the server," when there's actually no connection at all.
    final message = result.wasOffline
        ? l10n.staffSyncRequiresConnectionMessage
        : result.stoppedForAuth
        ? l10n.staffSyncStoppedForAuthMessage
        : l10n.staffSyncCompletedMessage(result.processed);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _syncAll() =>
      _runSync(_SyncTarget.all, () => ref.read(staffSyncNowProvider)());

  Future<void> _syncEcBoardEntries() => _runSync(
    _SyncTarget.ecBoardEntries,
    () => ref.read(staffSyncEcBoardEntriesOnlyProvider)(),
  );

  Future<void> _syncQuickCountEdit() => _runSync(
    _SyncTarget.quickCountEdit,
    () => ref.read(staffSyncQuickCountEditOnlyProvider)(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final eventsAsync = ref.watch(evacuationEventsLookupProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ecBoardTitle),
        actions: [
          SyncNowAction(
            isSyncing: _activeSync == _SyncTarget.all,
            onSync: _syncAll,
          ),
        ],
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
            isSyncingEcBoardEntries: _activeSync == _SyncTarget.ecBoardEntries,
            onSyncEcBoardEntries: _syncEcBoardEntries,
            isSyncingQuickCountEdit: _activeSync == _SyncTarget.quickCountEdit,
            onSyncQuickCountEdit: _syncQuickCountEdit,
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
    required this.isSyncingEcBoardEntries,
    required this.onSyncEcBoardEntries,
    required this.isSyncingQuickCountEdit,
    required this.onSyncQuickCountEdit,
  });

  final int centerId;
  final List<EvacuationEventLookup> events;
  final int selectedEventId;
  final ValueChanged<int> onEventChanged;
  final bool isSyncingEcBoardEntries;
  final VoidCallback onSyncEcBoardEntries;
  final bool isSyncingQuickCountEdit;
  final VoidCallback onSyncQuickCountEdit;

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

  Future<void> _openSectoralEdit(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SectoralQuickCountFormPage(
          centerId: centerId,
          evacuationEventId: selectedEventId,
        ),
      ),
    );
    ref.invalidate(ecBoardQuickCountProvider(centerId, selectedEventId));
    ref.invalidate(pendingQuickCountEditProvider(centerId, selectedEventId));
  }

  Future<void> _openQuickDeparture(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => QuickDepartureFormPage(
          centerId: centerId,
          evacuationEventId: selectedEventId,
        ),
      ),
    );
    ref.invalidate(ecBoardQuickCountProvider(centerId, selectedEventId));
  }

  /// [isOnline] disables the button outright while offline — matching
  /// `SyncNowAction`'s own AppBar convention — rather than letting the
  /// tap go through and land on a `wasOffline` result the staff member
  /// only finds out about from a SnackBar afterwards. The disabled
  /// label stays short ("Offline") rather than the full explanation:
  /// this sits in a `Row` next to a section title that needs its own
  /// room, and the full sentence — which fits fine as a SnackBar body
  /// or a tooltip — pushed that title into an unreadable one-word-per
  /// -line wrap the first time this was tried.
  Widget _syncNowButton({
    required AppLocalizations l10n,
    required bool isSyncing,
    required bool isOnline,
    required VoidCallback onSync,
  }) {
    if (isSyncing) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return Tooltip(
      message: isOnline
          ? l10n.ecBoardSyncNowInlineButton
          : l10n.staffSyncRequiresConnectionMessage,
      child: TextButton.icon(
        onPressed: isOnline ? onSync : null,
        icon: const Icon(Icons.sync_outlined, size: 18),
        label: Text(
          isOnline ? l10n.ecBoardSyncNowInlineButton : l10n.offlineModeLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(ecBoardEntriesForCenterProvider(centerId));
    final pendingQuickCountEditAsync = ref.watch(
      pendingQuickCountEditProvider(centerId, selectedEventId),
    );
    final isOnline = ref.watch(connectivityStatusProvider).value ?? false;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ecBoardQuickCountProvider(centerId, selectedEventId));
        ref.invalidate(ecBoardEntriesForCenterProvider(centerId));
        ref.invalidate(pendingQuickCountEditProvider(centerId, selectedEventId));
      },
      // Grouped by CATEGORY (Age & Sex, then Sectoral Group), each a
      // self-contained block with its own action button, confirmed
      // figures, and pending figures together — mirroring the
      // official printed EC Board form's own two-table layout, rather
      // than the earlier structure that grouped by STATE (every
      // confirmed figure first, then every pending figure after),
      // which put Add Evacuee and Edit Sectoral & 4Ps side by side at
      // the top with no visual link to the data each one actually
      // edits.
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _EventSelector(
            events: events,
            value: selectedEventId,
            onChanged: onEventChanged,
          ),
          const SizedBox(height: 16),
          if (isOnline)
            _EcBoardActionButton(
              icon: Icons.exit_to_app_outlined,
              label: l10n.ecBoardQuickDepartureTitle,
              subtitle: l10n.staffAddEvacuationCenterSubtitle,
              onPressed: () => _openQuickDeparture(context, ref),
              filled: false,
            )
          else
            _QuickDepartureOfflineNotice(label: l10n.ecBoardQuickDepartureTitle),
          const Divider(height: 40),

          // ── Age & Sex Disaggregation ─────────────────────────
          _EcBoardSectionHeader(
            icon: Icons.groups_2_outlined,
            title: l10n.ecBoardAgeSexSectionTitle,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.sync_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.ecBoardSyncNowExplanation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _EcBoardActionButton(
            icon: Icons.person_add_alt_1_outlined,
            label: l10n.ecBoardAddEvacueeTitle,
            subtitle: l10n.staffWorkspaceRegisterFamilySubtitle,
            onPressed: () => _openAddEvacuee(context, ref),
          ),
          const SizedBox(height: 20),
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
          _AgeSexQuickCountSection(
            centerId: centerId,
            evacuationEventId: selectedEventId,
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  l10n.ecBoardPendingSectionTitle,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Pushes only this queue — the Sectoral section's own
              // copy further down pushes only its pending edit, and
              // the AppBar's action is the one place that still pushes
              // everything at once.
              _syncNowButton(
                l10n: l10n,
                isSyncing: isSyncingEcBoardEntries,
                isOnline: isOnline,
                onSync: onSyncEcBoardEntries,
              ),
            ],
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
          const SizedBox(height: 12),
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
          const Divider(height: 40),

          // ── Sectoral Group & 4Ps ─────────────────────────────
          _EcBoardSectionHeader(
            icon: Icons.diversity_3_outlined,
            title: l10n.ecBoardSectoralSectionTitle,
          ),
          const SizedBox(height: 14),
          _EcBoardActionButton(
            icon: Icons.groups_outlined,
            label: l10n.ecBoardSectoralEditButton,
            subtitle: l10n.staffWorkspaceRegisterFamilySubtitle,
            onPressed: () => _openSectoralEdit(context, ref),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.ecBoardLastKnownSectionTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          _SectoralQuickCountSection(
            centerId: centerId,
            evacuationEventId: selectedEventId,
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  l10n.ecBoardPendingSectionTitle,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _syncNowButton(
                l10n: l10n,
                isSyncing: isSyncingQuickCountEdit,
                isOnline: isOnline,
                onSync: onSyncQuickCountEdit,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.ecBoardPendingSectionSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          pendingQuickCountEditAsync.when(
            data: (pending) => pending == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: EmptyState(
                      message: l10n.ecBoardPendingSectoralEmptyState,
                    ),
                  )
                : _PendingSectoralCard(
                    detail: pending,
                    onTap: () => _openSectoralEdit(context, ref),
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
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// A colored bar heading anchoring one of the page's two data
/// categories (Age & Sex, Sectoral Group) — mirrors the printed EC
/// Board form's own dark section bars, so the two categories read as
/// clearly separate at a glance while scrolling, the way they do on
/// the printed form.
class _EcBoardSectionHeader extends StatelessWidget {
  const _EcBoardSectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: semantic.navy,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
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

/// The "Age & Sex Disaggregation" half of the Last Known figures —
/// Cumulative/Now stats plus the full age-bracket table. Split out of
/// what used to be one combined `_QuickCountSection` so it can sit
/// directly under the Age & Sex section header, with the Sectoral
/// figures (from the exact same fetch) rendered separately by
/// [_SectoralQuickCountSection] under its own header further down the
/// page.
class _AgeSexQuickCountSection extends ConsumerWidget {
  const _AgeSexQuickCountSection({
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (count.isFromCache) ...[
              _CachedDataNotice(l10n: l10n, theme: theme),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: _CumulativeNowStat(
                    label: l10n.ecBoardFamiliesLabel,
                    cumulative: count.familiesCumulative,
                    now: count.familiesNow,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CumulativeNowStat(
                    label: l10n.ecBoardPersonsLabel,
                    cumulative: count.personsCumulative,
                    now: count.personsNow,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
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
                    count.ageGroupsTotal.maleCount,
                    count.ageGroupsTotal.femaleCount,
                  ),
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// The "Sectoral Group" half of the Last Known figures, plus the
/// standalone 4Ps Beneficiary Families count — grouped here rather
/// than with the Age & Sex table above because both are only ever
/// edited from the same place (the Edit Sectoral & 4Ps form), and
/// [count.updatedByName]/[count.updatedAt] are specifically about
/// *this* figure, not the age/sex one. See
/// [_AgeSexQuickCountSection]'s doc comment for why this is a
/// separate widget from what used to be one combined section.
class _SectoralQuickCountSection extends ConsumerWidget {
  const _SectoralQuickCountSection({
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
        if (count.sectoralGroups.isEmpty) {
          return EmptyState(message: l10n.ecBoardLastKnownEmpty);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (count.isFromCache) ...[
              _CachedDataNotice(l10n: l10n, theme: theme),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.ecBoardFourPsBeneficiaryFamilies,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${count.beneficiaries4ps}',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const Divider(height: 20),
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
            if (count.updatedAt != null) ...[
              const SizedBox(height: 12),
              if (count.updatedByName != null)
                Text(
                  l10n.ecBoardSectoralUpdatedBy(count.updatedByName!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              LastUpdatedLabel(timestamp: count.updatedAt),
            ],
          ],
        );
      },
    );
  }
}

class _CachedDataNotice extends StatelessWidget {
  const _CachedDataNotice({required this.l10n, required this.theme});

  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.cloud_off_outlined,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            l10n.ecBoardLastKnownFromCacheNotice,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// One "Cumulative" (everyone ever recorded here for this event, only
/// ever grows) vs "Now" (who's still physically here) figure — see
/// `EcBoardQuickCount.familiesCumulative`'s doc comment for why these
/// two numbers can and do legitimately differ (Quick Departure moves
/// "Now" down without ever touching "Cumulative").
class _CumulativeNowStat extends StatelessWidget {
  const _CumulativeNowStat({
    required this.label,
    required this.cumulative,
    required this.now,
  });

  final String label;
  final int cumulative;
  final int now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.4,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$now', style: theme.textTheme.headlineSmall),
              const SizedBox(width: 4),
              Text(
                l10n.ecBoardNowLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Text(
            l10n.ecBoardCumulativeValue(cumulative),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
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
        // Every real bracket always shown, zero-filled where there's
        // no pending entry yet — this mirrors the official EC Board
        // template's fixed row structure (every age category has its
        // own row on the printed form regardless of whether it has a
        // count), and matches the "Last Known" breakdown above it,
        // which the server already renders the same complete way.
        // Unclassified is the one exception, shown only when a
        // corrupted local entry actually produced one — it isn't a
        // row the template itself has.
        for (final bracket in ageBracketValues)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(localizedAgeBracket(context, bracket))),
                Text(
                  l10n.ecBoardMaleFemaleCount(
                    (counts[bracket] ?? (male: 0, female: 0)).male,
                    (counts[bracket] ?? (male: 0, female: 0)).female,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        if (counts[null] case final c?)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(l10n.ecBoardUnclassifiedLabel)),
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

/// One action button plus a short caption underneath explaining its
/// offline/online behavior — the one visual pattern every EC Board
/// action shares (see this app's own established phrasing on the
/// Staff Dashboard: "Works offline — syncs when you're ready" for
/// Register a Family, "Online only — not queued offline" for Add
/// Evacuation Center), reused verbatim here so staff learn it once and
/// recognize it everywhere. [filled] distinguishes the two
/// offline-capable actions (Add Evacuee, sectoral/4Ps — solid,
/// primary-styled buttons) from the online-only one (Quick Departure —
/// outlined, deliberately a step down in visual weight from an action
/// that isn't always available).
class _EcBoardActionButton extends StatelessWidget {
  const _EcBoardActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onPressed,
    this.filled = true,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        filled
            ? FilledButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
              ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Shown instead of the Quick Departure button while offline —
/// deliberately not just that same button greyed out: a disabled
/// button with no context reads as "temporarily broken," while this
/// explains the actual reason (see `QuickDepartureRequest`'s doc
/// comment) so staff understand it's a deliberate safety choice, not a
/// bug or an oversight.
class _QuickDepartureOfflineNotice extends StatelessWidget {
  const _QuickDepartureOfflineNotice({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final warning =
        theme.extension<AppSemanticColors>()?.warning ?? Colors.amber.shade800;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_outlined, color: warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(color: warning),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.ecBoardQuickDepartureOfflineExplanation,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// This device's own not-yet-synced sectoral/4Ps edit — shown as a
/// distinct card (matching the visual weight of a pending evacuee
/// tile) rather than merged into the "Last Known" figures above, since
/// this hasn't been confirmed by the server yet.
class _PendingSectoralCard extends StatelessWidget {
  const _PendingSectoralCard({required this.detail, required this.onTap});

  final PendingQuickCountEditDetail detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final summary = detail.summary;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: switch (summary.status) {
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
        title: Text(l10n.ecBoardPendingSectoralCardTitle),
        subtitle: Text(
          summary.lastErrorMessage ?? l10n.ecBoardPendingSectoralCardSubtitle,
        ),
      ),
    );
  }
}
