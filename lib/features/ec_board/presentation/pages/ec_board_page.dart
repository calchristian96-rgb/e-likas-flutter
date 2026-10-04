import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/data_freshness_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
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
import '../../../evacuation_centers/presentation/providers/evacuation_centers_provider.dart'
    show centerByIdProvider;
import '../../domain/entities/age_bracket.dart';
import '../../domain/entities/ec_board_quick_count.dart';
import '../../domain/entities/pending_ec_board_entry.dart';
import '../../domain/entities/sectoral_group.dart';
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

/// Which queue a Sync Now tap is pushing — [all] is the AppBar's own
/// action; [ecBoardEntries] is the contextual button next to this
/// device's pending evacuees. `StaffSyncService._running` already
/// guarantees only one sync of any kind runs app-wide at once, so this
/// only needs to track *which* button should show its own spinner.
enum _SyncTarget { all, ecBoardEntries }

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _syncAll() =>
      _runSync(_SyncTarget.all, () => ref.read(staffSyncNowProvider)());

  Future<void> _syncEcBoardEntries() => _runSync(
    _SyncTarget.ecBoardEntries,
    () => ref.read(staffSyncEcBoardEntriesOnlyProvider)(),
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

/// Width of each of the Male / Female / Total columns — one value for
/// every row on the board, so the three number columns line up from the
/// Age & Sex table straight through the Sectoral table, and on down
/// through the "Added on this device" rows beneath. Sized for a 360dp
/// phone: the label column takes whatever is left and wraps if it must,
/// so nothing ever scrolls sideways.
const double _numColWidth = 56;

/// Both tables sit side by side only when the sheet itself is at least
/// this wide (tablet/landscape) — otherwise they stack.
const double _sideBySideMinWidth = 720;

const String _dash = '—';

class _EcBoardBody extends ConsumerWidget {
  const _EcBoardBody({
    required this.centerId,
    required this.events,
    required this.selectedEventId,
    required this.onEventChanged,
    required this.isSyncingEcBoardEntries,
    required this.onSyncEcBoardEntries,
  });

  final int centerId;
  final List<EvacuationEventLookup> events;
  final int selectedEventId;
  final ValueChanged<int> onEventChanged;
  final bool isSyncingEcBoardEntries;
  final VoidCallback onSyncEcBoardEntries;

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
    // An online add lands straight in the server's live figures.
    ref.invalidate(ecBoardQuickCountProvider(centerId, selectedEventId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entriesAsync = ref.watch(ecBoardEntriesForCenterProvider(centerId));
    final isOnline = ref.watch(connectivityStatusProvider).value ?? false;
    final countAsync = ref.watch(
      ecBoardQuickCountProvider(centerId, selectedEventId),
    );
    final center = ref.watch(centerByIdProvider(centerId)).value;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ecBoardQuickCountProvider(centerId, selectedEventId));
        ref.invalidate(ecBoardEntriesForCenterProvider(centerId));
      },
      // Add Evacuee first (the everyday action), then the board as one
      // sheet in the official template's order, then this device's
      // not-yet-synced additions kept apart from it. Departures are
      // recorded on the family's record (Registered Families), not here
      // -- the board no longer has Quick Departure, as on the web.
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _EcBoardActionButton(
            icon: Icons.person_add_alt_1_outlined,
            label: l10n.ecBoardAddEvacueeTitle,
            subtitle: l10n.staffWorkspaceRegisterFamilySubtitle,
            onPressed: () => _openAddEvacuee(context, ref),
          ),
          const SizedBox(height: 16),
          _BoardSheet(
            barangayName: center?.barangay,
            centerName: center?.name,
            events: events,
            selectedEventId: selectedEventId,
            onEventChanged: onEventChanged,
            countAsync: countAsync,
            onRetry: () => ref.invalidate(
              ecBoardQuickCountProvider(centerId, selectedEventId),
            ),
          ),
          const SizedBox(height: 20),
          _PendingSection(
            centerId: centerId,
            entriesAsync: entriesAsync,
            selectedEventId: selectedEventId,
            isOnline: isOnline,
            isSyncing: isSyncingEcBoardEntries,
            onSync: onSyncEcBoardEntries,
          ),
        ],
      ),
    );
  }
}

/// The EC Information Board as one continuous sheet, like the printed
/// form: the header block (Barangay, Evacuation center, Event, As of,
/// Families, Persons, 4Ps families) and then the Age & Sex and Sectoral
/// tables on one shared column grid. Every figure is the server's own —
/// nothing from this device is ever added in. Until a board has been
/// fetched at least once, every figure is a dash, never a zero.
class _BoardSheet extends StatelessWidget {
  const _BoardSheet({
    required this.barangayName,
    required this.centerName,
    required this.events,
    required this.selectedEventId,
    required this.onEventChanged,
    required this.countAsync,
    required this.onRetry,
  });

  final String? barangayName;
  final String? centerName;
  final List<EvacuationEventLookup> events;
  final int selectedEventId;
  final ValueChanged<int> onEventChanged;
  final AsyncValue<EcBoardQuickCount> countAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Keeps showing the previous figures while a refresh is in flight.
    final count = countAsync.value;
    final neverFetched = count == null && countAsync.hasError;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 3,
            child: countAsync.isLoading
                ? const LinearProgressIndicator(minHeight: 3)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: _BoardHeader(
              barangayName: barangayName,
              centerName: centerName,
              events: events,
              selectedEventId: selectedEventId,
              onEventChanged: onEventChanged,
              count: count,
              neverFetched: neverFetched,
              onRetry: onRetry,
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final ageSex = _AgeSexTable(count: count);
              final sectoral = _SectoralTable(count: count);
              if (constraints.maxWidth >= _sideBySideMinWidth) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: ageSex),
                      VerticalDivider(
                        width: 1,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      Expanded(child: sectoral),
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [ageSex, sectoral],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BoardHeader extends StatelessWidget {
  const _BoardHeader({
    required this.barangayName,
    required this.centerName,
    required this.events,
    required this.selectedEventId,
    required this.onEventChanged,
    required this.count,
    required this.neverFetched,
    required this.onRetry,
  });

  final String? barangayName;
  final String? centerName;
  final List<EvacuationEventLookup> events;
  final int selectedEventId;
  final ValueChanged<int> onEventChanged;
  final EcBoardQuickCount? count;
  final bool neverFetched;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = count;
    String pair(int cumulative, int now) => '$cumulative / $now';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderRow(
          label: l10n.staffRegFieldBarangay,
          value: barangayName?.isNotEmpty == true ? barangayName! : _dash,
        ),
        _HeaderRow(
          label: l10n.ecBoardHeaderCenter,
          value: centerName?.isNotEmpty == true ? centerName! : _dash,
          emphasize: true,
        ),
        const SizedBox(height: 10),
        _EventSelector(
          events: events,
          value: selectedEventId,
          onChanged: onEventChanged,
        ),
        const SizedBox(height: 10),
        _AsOfRow(count: c, neverFetched: neverFetched, onRetry: onRetry),
        Divider(height: 20, color: theme.colorScheme.outlineVariant),
        _HeaderRow(
          label: l10n.ecBoardHeaderFamilies,
          value: c == null ? _dash : pair(c.familiesCumulative, c.familiesNow),
          emphasize: true,
        ),
        _HeaderRow(
          label: l10n.ecBoardHeaderPersons,
          value: c == null ? _dash : pair(c.personsCumulative, c.personsNow),
          emphasize: true,
        ),
        _HeaderRow(
          label: l10n.ecBoardFourPsBeneficiaryFamilies,
          value: c == null ? _dash : '${c.beneficiaries4ps}',
          emphasize: true,
        ),
      ],
    );
  }
}

/// One label/value line of the board header — the label muted on the
/// left, the value on the right, wrapping rather than overflowing.
class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style:
                  (emphasize
                          ? theme.textTheme.titleSmall
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: emphasize ? FontWeight.w700 : null,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "As of": when these figures last arrived from the server — never the
/// current time. Offline (the saved copy) it keeps that time and says
/// how old it is, in amber; a board never fetched says so.
class _AsOfRow extends StatelessWidget {
  const _AsOfRow({
    required this.count,
    required this.neverFetched,
    required this.onRetry,
  });

  final EcBoardQuickCount? count;
  final bool neverFetched;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final warning =
        theme.extension<AppSemanticColors>()?.warning ?? Colors.amber.shade800;
    final c = count;
    final fetchedAt = c?.fetchedAt;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final String value;
    if (fetchedAt != null) {
      value = DateFormat.yMMMd().add_jm().format(fetchedAt.toLocal());
    } else if (neverFetched) {
      value = l10n.ecBoardAsOfNotYetFetched;
    } else {
      value = _dash;
    }
    final attention = neverFetched || (c?.isFromCache ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Text(
                l10n.ecBoardAsOf,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (attention) ...[
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 16,
                          color: warning,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          value,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (fetchedAt != null)
                    Text(formatElapsedSince(fetchedAt), style: muted),
                ],
              ),
            ),
          ],
        ),
        if (c?.isFromCache ?? false) ...[
          const SizedBox(height: 6),
          _AttentionNote(text: l10n.ecBoardLastKnownFromCacheNotice),
        ],
        if (neverFetched) ...[
          const SizedBox(height: 6),
          _AttentionNote(
            text: l10n.ecBoardNotYetFetchedHelp,
            action: TextButton(onPressed: onRetry, child: Text(l10n.tryAgain)),
          ),
        ],
      ],
    );
  }
}

/// A short amber-marked note — the board's one "attention" style. Amber
/// is kept to the icon, border and tint; the text stays the theme's own
/// color so it reads in both light and dark mode.
class _AttentionNote extends StatelessWidget {
  const _AttentionNote({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning =
        theme.extension<AppSemanticColors>()?.warning ?? Colors.amber.shade800;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: warning.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (action case final a?)
            Align(alignment: Alignment.centerRight, child: a),
        ],
      ),
    );
  }
}

/// A table's heading bar — the printed form's dark section bar, with the
/// shared Male / Female / Total column headings on the same line.
class _TableHeading extends StatelessWidget {
  const _TableHeading({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    // Navy in both themes (see AppSemanticColors), so white reads on it.
    final head = theme.textTheme.labelMedium?.copyWith(
      color: Colors.white.withValues(alpha: 0.85),
      fontWeight: FontWeight.w600,
    );
    return Container(
      color: semantic.navy,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          for (final h in [
            l10n.staffRegSexMale,
            l10n.staffRegSexFemale,
            l10n.ecBoardTotalLabel,
          ])
            SizedBox(
              width: _numColWidth,
              child: Text(h, textAlign: TextAlign.end, style: head),
            ),
        ],
      ),
    );
  }
}

enum _RowKind { normal, attention, total }

/// One row on the shared grid: a label, then Male / Female / Total in
/// fixed-width columns. Values are strings so a never-fetched board can
/// show dashes and the pending rows can show "+N".
class _GridRow extends StatelessWidget {
  const _GridRow({
    required this.label,
    required this.male,
    required this.female,
    required this.total,
    this.kind = _RowKind.normal,
  });

  final String label;
  final String male;
  final String female;
  final String total;
  final _RowKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning =
        theme.extension<AppSemanticColors>()?.warning ?? Colors.amber.shade800;
    final isTotal = kind == _RowKind.total;
    final base =
        (isTotal ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)
            ?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: isTotal ? FontWeight.w800 : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            );
    final number = base?.copyWith(
      fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: switch (kind) {
          _RowKind.total => theme.colorScheme.secondaryContainer.withValues(
            alpha: 0.55,
          ),
          _RowKind.attention => warning.withValues(alpha: 0.12),
          _RowKind.normal => null,
        },
        border: Border(
          top: BorderSide(
            color: isTotal
                ? theme.colorScheme.outline
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: isTotal ? 1.5 : 1,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          isTotal ? 10 : 8,
          16,
          isTotal ? 10 : 8,
        ),
        child: Row(
          children: [
            if (kind == _RowKind.attention) ...[
              Icon(Icons.error_outline, size: 16, color: warning),
              const SizedBox(width: 6),
            ],
            Expanded(child: Text(label, style: base)),
            for (final v in [male, female, total])
              SizedBox(
                width: _numColWidth,
                child: Text(v, textAlign: TextAlign.end, style: number),
              ),
          ],
        ),
      ),
    );
  }
}

String _n(int? v) => v == null ? _dash : '$v';

class _AgeSexTable extends StatelessWidget {
  const _AgeSexTable({required this.count});

  final EcBoardQuickCount? count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = count;
    final byBracket = {
      for (final g in c?.ageGroups ?? const <EcBoardAgeGroupCount>[])
        g.ageBracket: g,
    };
    // The server's own "unclassified" row: people missing a sex or age
    // group. Its total is the server's, since M+F leaves out anyone
    // whose sex is also unknown.
    final unclassified = byBracket[null];
    final unclassifiedTotal = unclassified == null
        ? null
        : (unclassified.totalCount ??
              unclassified.maleCount + unclassified.femaleCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TableHeading(
          icon: Icons.groups_2_outlined,
          title: l10n.ecBoardAgeSexSectionTitle,
        ),
        for (final bracket in ageBracketValues)
          _GridRow(
            label: localizedAgeBracket(context, bracket),
            male: _n(c == null ? null : byBracket[bracket]?.maleCount ?? 0),
            female: _n(c == null ? null : byBracket[bracket]?.femaleCount ?? 0),
            total: _n(
              c == null
                  ? null
                  : (byBracket[bracket]?.maleCount ?? 0) +
                        (byBracket[bracket]?.femaleCount ?? 0),
            ),
          ),
        _GridRow(
          label: l10n.ecBoardUnclassifiedLabel,
          male: _n(c == null ? null : unclassified?.maleCount ?? 0),
          female: _n(c == null ? null : unclassified?.femaleCount ?? 0),
          total: _n(c == null ? null : unclassifiedTotal ?? 0),
          // Amber only when there's actually someone to classify.
          kind: (unclassifiedTotal ?? 0) > 0
              ? _RowKind.attention
              : _RowKind.normal,
        ),
        _GridRow(
          label: l10n.ecBoardTotalLabel,
          male: _n(c?.ageGroupsTotal.maleCount),
          female: _n(c?.ageGroupsTotal.femaleCount),
          total: _n(c?.ageGroupsTotal.totalPersons),
          kind: _RowKind.total,
        ),
      ],
    );
  }
}

/// All 8 sectoral rows, live and read-only. No total row: the groups
/// overlap (a solo parent can also be a PWD), so a sum would mean
/// nothing — the server computes none either.
class _SectoralTable extends StatelessWidget {
  const _SectoralTable({required this.count});

  final EcBoardQuickCount? count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = count;
    final byGroup = {
      for (final g in c?.sectoralGroups ?? const <EcBoardSectoralGroupCount>[])
        g.group: g,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TableHeading(
          icon: Icons.diversity_3_outlined,
          title: l10n.ecBoardSectoralSectionTitle,
        ),
        for (final group in sectoralGroupValues)
          _GridRow(
            label: localizedSectoralGroup(context, group),
            male: _n(c == null ? null : byGroup[group]?.maleCount ?? 0),
            female: _n(c == null ? null : byGroup[group]?.femaleCount ?? 0),
            total: _n(c == null ? null : byGroup[group]?.total ?? 0),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Text(
            l10n.ecBoardSectoralLiveExplanation,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// This device's not-yet-synced Add Evacuee entries — deliberately a
/// separate amber section under the board, never numbers mixed into its
/// rows: a "+N" squeezed into each board row would crowd the narrow
/// Male/Female/Total columns on a phone and blur which figures the
/// server has confirmed. Only rows with something pending are listed,
/// on the same column grid as the board so they still line up.
class _PendingSection extends StatelessWidget {
  const _PendingSection({
    required this.centerId,
    required this.entriesAsync,
    required this.selectedEventId,
    required this.isOnline,
    required this.isSyncing,
    required this.onSync,
  });

  final int centerId;
  final AsyncValue<List<PendingEcBoardEntrySummary>> entriesAsync;
  final int selectedEventId;
  final bool isOnline;
  final bool isSyncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final warning =
        theme.extension<AppSemanticColors>()?.warning ?? Colors.amber.shade800;
    final entries = entriesAsync.value ?? const <PendingEcBoardEntrySummary>[];
    // The board is per event, so its pending counterpart is too; the
    // entry list below still shows every event's entries for managing.
    final forEvent = entries
        .where((e) => e.evacuationEventId == selectedEventId)
        .toList();

    final ageCounts = <AgeBracket?, ({int male, int female})>{};
    for (final e in forEvent) {
      final c = ageCounts[e.ageBracket] ?? (male: 0, female: 0);
      ageCounts[e.ageBracket] = switch (e.sex) {
        'female' => (male: c.male, female: c.female + 1),
        'male' => (male: c.male + 1, female: c.female),
        _ => c,
      };
    }
    final sectoral = countPendingSectoral(forEvent);
    String plus(int v) => '+$v';
    List<Widget> rowsFor(Iterable<(String, ({int male, int female}))> items) =>
        [
          for (final (label, c) in items)
            if (c.male + c.female > 0)
              _GridRow(
                label: label,
                male: plus(c.male),
                female: plus(c.female),
                total: plus(c.male + c.female),
              ),
        ];
    final ageRows = rowsFor([
      for (final b in ageBracketValues)
        (localizedAgeBracket(context, b), ageCounts[b] ?? (male: 0, female: 0)),
      (l10n.ecBoardUnclassifiedLabel, ageCounts[null] ?? (male: 0, female: 0)),
    ]);
    final sectoralRows = rowsFor([
      for (final g in sectoralGroupValues)
        (localizedSectoralGroup(context, g), sectoral[g]!),
    ]);
    final subheading = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warning.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Icon(Icons.cloud_upload_outlined, size: 20, color: warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.ecBoardPendingSectionTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Pushes only this queue (evacuees, with the sectoral
                // details and household answers they carry); the AppBar's
                // action is the one place that pushes everything at once.
                _SyncNowButton(
                  isSyncing: isSyncing,
                  isOnline: isOnline,
                  onSync: onSync,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            child: Text(
              l10n.ecBoardPendingSectionSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (entriesAsync.hasError && entriesAsync.value == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(l10n.staffPendingListError),
            )
          else if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                l10n.ecBoardPendingListEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else ...[
            if (ageRows.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(l10n.ecBoardAgeSexSectionTitle, style: subheading),
              ),
              ...ageRows,
            ],
            if (sectoralRows.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Text(
                  l10n.ecBoardSectoralSectionTitle,
                  style: subheading,
                ),
              ),
              ...sectoralRows,
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Column(
                children: [
                  for (final entry in entries)
                    _PendingEntryTile(centerId: centerId, entry: entry),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Disabled outright while offline — matching `SyncNowAction`'s own
/// AppBar convention — rather than letting the tap land on a
/// `wasOffline` result. The disabled label stays short ("Offline") so
/// the section title beside it keeps its room.
class _SyncNowButton extends StatelessWidget {
  const _SyncNowButton({
    required this.isSyncing,
    required this.isOnline,
    required this.onSync,
  });

  final bool isSyncing;
  final bool isOnline;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (isSyncing) {
      return const Padding(
        padding: EdgeInsets.all(12),
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
        isDense: true,
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
/// recognize it everywhere.
class _EcBoardActionButton extends StatelessWidget {
  const _EcBoardActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
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

