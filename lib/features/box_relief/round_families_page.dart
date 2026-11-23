import '../../core/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/cache/staff_read_cache.dart';
import '../../core/utils/data_freshness_formatter.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/stat_strip.dart';
import '../../l10n/app_localizations.dart';
import '../outbox/domain/pending_action.dart';
import '../outbox/presentation/outbox_providers.dart';
import 'box_relief_models.dart';
import '../../core/widgets/lock_note.dart';
import '../staff_shell/event_lock.dart';

class RoundFamily {
  const RoundFamily({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.given,
    required this.priorityOrder,
    this.priorityLabel,
    this.handoutId,
    this.nextInLine = false,
    this.higherPriorityWaiting = 0,
    this.fromBarangay,
    this.stayingIn,
    this.mayGive = true,
    this.canGive = true,
  });

  /// A family from another barangay staying here: the host gives its
  /// box ("From {barangay}", `from_barangay`).
  final String? fromBarangay;

  /// Where the family stays now (`staying_in`), null when not recorded.
  final StayingIn? stayingIn;

  /// This barangay gives the family its box (`may_give`; always true in
  /// `puroks`). Stock is a separate matter: [canGive].
  final bool mayGive;

  /// No box yet in this round and boxes left (`can_give`).
  final bool canGive;

  /// The next family in the suggested order across the barangay
  /// (backend 02a41f4): marked "Next in line".
  final bool nextInLine;

  /// Families of a higher priority tier still without a box: giving to
  /// this one first asks for confirmation (a warning, never a block).
  final int higherPriorityWaiting;

  final int id;
  final String name;
  final int memberCount;
  final bool given;

  /// The handout that stands (the one to void), when given.
  final int? handoutId;

  /// Infant, Pregnant / lactating, PWD / senior, Child- or
  /// single-headed; null for none of these.
  final String? priorityLabel;

  /// Place in the suggested order within its purok (1 = first).
  final int priorityOrder;

  factory RoundFamily.fromJson(Map<String, dynamic> j) => RoundFamily(
    id: j['id'] as int,
    name: j['name'] as String? ?? '',
    memberCount: (j['member_count'] as num?)?.toInt() ?? 0,
    given: j['given'] == true,
    handoutId: j['handout_id'] as int?,
    priorityLabel: j['priority_label'] as String?,
    priorityOrder: (j['priority_order'] as num?)?.toInt() ?? 0,
    nextInLine: j['next_in_line'] == true,
    higherPriorityWaiting: (j['higher_priority_waiting'] as num?)?.toInt() ?? 0,
    fromBarangay:
        (j['from_barangay'] as Map<String, dynamic>?)?['name'] as String?,
    stayingIn: StayingIn.fromJson(j['staying_in'], hostName: j['host_name']),
    mayGive: j['may_give'] != false,
    canGive: j['can_give'] != false,
  );
}

/// `staying_in` (apps-api-2026-11-24.md 1.1): `{barangay: {id, name},
/// center: {id, name} or null, private_house, other_barangay}`.
class StayingIn {
  const StayingIn({
    this.barangay,
    this.center,
    this.privateHouse = false,
    this.otherBarangay = false,
    this.hostName,
  });

  static StayingIn? fromJson(Object? raw, {Object? hostName}) {
    if (raw is! Map<String, dynamic>) return null;
    return StayingIn(
      barangay: (raw['barangay'] as Map<String, dynamic>?)?['name'] as String?,
      center: (raw['center'] as Map<String, dynamic>?)?['name'] as String?,
      privateHouse: raw['private_house'] == true,
      otherBarangay: raw['other_barangay'] == true,
      hostName: hostName is String && hostName.isNotEmpty ? hostName : null,
    );
  }

  final String? barangay;
  final String? center;
  final bool privateHouse;
  final bool otherBarangay;
  final String? hostName;

  /// "Bay Elementary School", "Private house (Juan Reyes)".
  String place(AppLocalizations l10n) => privateHouse
      ? l10n.reliefPrivateHouse(hostName ?? '–')
      : center ?? barangay ?? '';
}

/// One of the barangay's own families staying in another barangay's
/// center (`staying_elsewhere[]`): that barangay gives its box. Shown
/// for information only, never with a Give button.
class StayingElsewhere {
  const StayingElsewhere({
    required this.id,
    required this.name,
    required this.memberCount,
    this.purok,
    this.stayingIn,
    this.givesBox,
    this.given = false,
  });

  factory StayingElsewhere.fromJson(Map<String, dynamic> j) => StayingElsewhere(
    id: (j['id'] as num).toInt(),
    name: j['name'] as String? ?? '',
    memberCount: (j['member_count'] as num?)?.toInt() ?? 0,
    purok: (j['purok'] as Map<String, dynamic>?)?['name'] as String?,
    stayingIn: StayingIn.fromJson(j['staying_in']),
    givesBox: (j['gives_box'] as Map<String, dynamic>?)?['name'] as String?,
    given: j['given'] == true,
  );

  final int id;
  final String name;
  final int memberCount;
  final String? purok;
  final StayingIn? stayingIn;

  /// The barangay that gives its box.
  final String? givesBox;
  final bool given;
}

class PurokGroup {
  const PurokGroup({required this.name, required this.families});

  /// Null for families with no purok (listed last).
  final String? name;
  final List<RoundFamily> families;
}

class RoundFamilies {
  const RoundFamilies({
    required this.roundNumber,
    required this.figures,
    required this.puroks,
    this.stayingElsewhere = const [],
  });

  final int roundNumber;
  final BoxFigures figures;
  final List<PurokGroup> puroks;
  final List<StayingElsewhere> stayingElsewhere;

  factory RoundFamilies.fromJson(Map<String, dynamic> j) => RoundFamilies(
    roundNumber:
        ((j['round'] as Map<String, dynamic>?)?['round_number'] as num?)
            ?.toInt() ??
        0,
    figures: BoxFigures.fromJson(
      j['figures'] as Map<String, dynamic>? ?? const {},
    ),
    puroks: [
      for (final p in j['puroks'] as List? ?? const [])
        PurokGroup(
          name:
              ((p as Map<String, dynamic>)['purok']
                      as Map<String, dynamic>?)?['name']
                  as String?,
          families: [
            for (final f in p['families'] as List? ?? const [])
              RoundFamily.fromJson(f as Map<String, dynamic>),
          ],
        ),
    ],
    stayingElsewhere: [
      for (final f in j['staying_elsewhere'] as List? ?? const [])
        StayingElsewhere.fromJson(f as Map<String, dynamic>),
    ],
  );
}

/// `GET /box-relief/rounds/{round}/families?order=priority`, saved for
/// offline; refetched after each sync.
final roundFamiliesProvider = FutureProvider.autoDispose
    .family<({RoundFamilies data, DateTime fetchedAt, bool fromCache}), int>((
      ref,
      roundId,
    ) async {
      ref.watch(outboxRevisionProvider);
      final read = await ref
          .watch(staffReadCacheProvider)
          .get(
            '/box-relief/rounds/$roundId/families',
            query: {'order': 'priority'},
          );
      return (
        data: RoundFamilies.fromJson(read.data),
        fetchedAt: read.fetchedAt,
        fromCache: read.isFromCache,
      );
    });

/// Give 1 box per family in this round, purok by purok, in the
/// suggested priority order (C22). Giving works offline through the
/// queue; a wrong handout is voided with a reason from the row's "...".
class RoundFamiliesPage extends ConsumerStatefulWidget {
  const RoundFamiliesPage({super.key, required this.roundId});

  final int roundId;

  @override
  ConsumerState<RoundFamiliesPage> createState() => _RoundFamiliesPageState();
}

class _RoundFamiliesPageState extends ConsumerState<RoundFamiliesPage> {
  bool _byName = false;

  String _giveKey(int familyId) => 'round:${widget.roundId}:family:$familyId';
  String _voidKey(int handoutId) => 'handout:$handoutId:void';

  Future<void> _give(RoundFamily f, int roundNumber) async {
    final l10n = AppLocalizations.of(context);
    // Out of the priority order: ask, the same as the web
    // (apps-api-2026-11-24.md 1.3). The server never blocks it.
    if (f.higherPriorityWaiting > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.reliefOutOfOrderTitle),
          content: Text(l10n.reliefOutOfOrderBody(f.higherPriorityWaiting)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.reliefGiveBox),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    await enqueueStaffAction(
      ref,
      kind: PendingActionKind.boxHandout,
      method: 'POST',
      path: '/box-relief/rounds/${widget.roundId}/handouts',
      body: {'family_id': f.id},
      summary: l10n.reliefGiveSummary(f.name, roundNumber),
      subjectKey: _giveKey(f.id),
    );
  }

  Future<void> _void(RoundFamily f) async {
    final l10n = AppLocalizations.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _VoidDialog(familyName: f.name),
    );
    if (reason == null || f.handoutId == null) return;
    await enqueueStaffAction(
      ref,
      kind: PendingActionKind.boxHandoutVoid,
      method: 'POST',
      path: '/box-relief/handouts/${f.handoutId}/void',
      body: {'reason': reason},
      summary: l10n.reliefVoidSummary(f.name),
      subjectKey: _voidKey(f.handoutId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(roundFamiliesProvider(widget.roundId));
    final queued = {
      for (final a in ref.watch(pendingActionsProvider).value ?? const [])
        ?a.subjectKey,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          async.value == null
              ? l10n.reliefGiveBoxes
              : l10n.reliefRound(async.value!.data.roundNumber),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: ErrorState(
            message: l10n.reliefNeedsConnectionFirst,
            onRetry: () =>
                ref.invalidate(roundFamiliesProvider(widget.roundId)),
          ),
        ),
        data: (result) {
          final data = result.data;
          final queuedGives = [
            for (final g in data.puroks)
              for (final f in g.families)
                if (!f.given && queued.contains(_giveKey(f.id))) f,
          ].length;
          final leftToGive = data.figures.leftToGive - queuedGives;
          final locked = ref.watch(eventMonitoredProvider);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(roundFamiliesProvider(widget.roundId));
              await ref.read(staffSyncAllProvider)();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: pagePadding(context),
              children: [
                if (result.fromCache)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l10n.savedCopyAge(formatElapsedSince(result.fetchedAt)),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (locked) ...[const LockNote(), const SizedBox(height: 16)],
                StatStrip(
                  items: [
                    StatItem(l10n.reliefReceived, '${data.figures.received}'),
                    StatItem(
                      l10n.reliefGiven,
                      '${data.figures.given + queuedGives}',
                    ),
                    StatItem(
                      l10n.reliefLeftToGive,
                      '${leftToGive < 0 ? 0 : leftToGive}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text(l10n.reliefByPriority),
                    ),
                    ButtonSegment(value: true, label: Text(l10n.reliefByName)),
                  ],
                  selected: {_byName},
                  onSelectionChanged: (s) => setState(() => _byName = s.first),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.reliefSuggestedOrderNote,
                  style: theme.textTheme.bodySmall,
                ),
                for (final group in data.puroks) ...[
                  const SizedBox(height: 24),
                  Text(
                    l10n.reliefPurokHeading(
                      group.name ?? l10n.purokNone,
                      group.families.where((f) => f.given).length,
                      group.families.length,
                    ),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final f
                            in [...group.families]..sort(
                              (a, b) => _byName
                                  ? a.name.compareTo(b.name)
                                  : a.priorityOrder.compareTo(b.priorityOrder),
                            ))
                          _FamilyTile(
                            family: f,
                            queuedGive: queued.contains(_giveKey(f.id)),
                            queuedVoid:
                                f.handoutId != null &&
                                queued.contains(_voidKey(f.handoutId!)),
                            boxesLeft: leftToGive > 0,
                            locked: locked,
                            onGive: () => _give(f, data.roundNumber),
                            onVoid: () => _void(f),
                          ),
                      ],
                    ),
                  ),
                ],
                if (data.stayingElsewhere.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    l10n.reliefStayingElsewhereTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    l10n.reliefStayingElsewhereNote,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final f in data.stayingElsewhere)
                          _ElsewhereTile(family: f),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FamilyTile extends StatelessWidget {
  const _FamilyTile({
    required this.family,
    required this.queuedGive,
    required this.queuedVoid,
    required this.boxesLeft,
    required this.onGive,
    required this.onVoid,
    this.locked = false,
  });

  /// The event is being monitored: no handouts yet.
  final bool locked;

  final RoundFamily family;
  final bool queuedGive;
  final bool queuedVoid;

  /// Confirmed boxes left to give (received - given, counting the
  /// handouts still on this phone). None left: "Waiting for more boxes".
  final bool boxesLeft;
  final VoidCallback onGive;
  final VoidCallback onVoid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final given = (family.given && !queuedVoid) || queuedGive;
    final Widget trailing;
    if (queuedGive || queuedVoid) {
      trailing = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 136),
        child: Text(
          queuedVoid ? l10n.reliefVoidWaiting : l10n.reliefGivenWaiting,
          textAlign: TextAlign.end,
          style: theme.textTheme.labelMedium,
        ),
      );
    } else if (!family.mayGive && !family.given) {
      trailing = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 136),
        child: Text(
          l10n.reliefNotOurs,
          textAlign: TextAlign.end,
          style: theme.textTheme.labelMedium,
        ),
      );
    } else if (locked && !family.given) {
      trailing = Icon(
        Icons.lock_outline,
        color: theme.colorScheme.onSurfaceVariant,
        semanticLabel: l10n.lockAvailableWhenActive,
      );
    } else if (family.given) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.reliefGiven,
            style: theme.textTheme.labelMedium?.copyWith(
              color: semantic.success,
              fontWeight: FontWeight.w600,
            ),
          ),
          MoreButton(
            title: family.name,
            actions: [
              SheetAction(
                label: l10n.reliefVoidHandout,
                icon: Icons.undo,
                destructive: true,
                onTap: onVoid,
              ),
            ],
          ),
        ],
      );
    } else {
      // Giving needs only confirmed boxes left; with none left the button
      // waits (disabled) until more are confirmed (backend 02a41f4).
      // At most 136 wide so the family's name keeps its room on a
      // 360 dp phone; a long label wraps.
      // Only the next family in line gets the primary Give button; the
      // others can still be given (out of order asks first).
      final label = Text(
        boxesLeft ? l10n.reliefGiveBox : l10n.reliefWaitingForBoxes,
        textAlign: TextAlign.center,
      );
      const padding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      trailing = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 136),
        child: family.nextInLine
            ? FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(96, 48),
                  padding: padding,
                ),
                onPressed: boxesLeft ? onGive : null,
                child: label,
              )
            : OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(96, 48),
                  padding: padding,
                ),
                onPressed: boxesLeft ? onGive : null,
                child: label,
              ),
      );
    }
    return ListTile(
      minTileHeight: 64,
      title: Text(family.name),
      subtitle: Text(
        [
          if (family.nextInLine && !given) l10n.reliefNextInLine,
          l10n.ecBoardFamilyMembers(family.memberCount),
          if (family.priorityLabel != null)
            l10n.reliefPriority(family.priorityLabel!),
          if (family.fromBarangay != null)
            l10n.reliefFromBarangay(family.fromBarangay!),
          if (family.stayingIn != null &&
              family.stayingIn!.place(l10n).isNotEmpty)
            family.stayingIn!.place(l10n),
        ].join(' · '),
      ),
      leading: Icon(
        given ? Icons.check_circle : Icons.radio_button_unchecked,
        color: given ? semantic.success : theme.colorScheme.onSurfaceVariant,
      ),
      trailing: trailing,
    );
  }
}

/// A family of ours staying in another barangay: read only.
class _ElsewhereTile extends StatelessWidget {
  const _ElsewhereTile({required this.family});

  final StayingElsewhere family;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final stay = family.stayingIn;
    final where = [
      ?stay?.barangay,
      if (stay?.center != null) stay!.center!,
    ].join(', ');
    return ListTile(
      minTileHeight: 64,
      leading: Icon(
        family.given ? Icons.check_circle : Icons.swap_horiz,
        color: family.given
            ? semantic.success
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(family.name),
      subtitle: Text(
        [
          l10n.ecBoardFamilyMembers(family.memberCount),
          ?family.purok,
          if (where.isNotEmpty) l10n.reliefStayingIn(where),
          if (family.givesBox != null) l10n.reliefBoxFrom(family.givesBox!),
        ].join(' · '),
      ),
      trailing: Text(
        family.given ? l10n.reliefGiven : l10n.reliefNotGivenYet,
        style: theme.textTheme.labelMedium?.copyWith(
          color: family.given ? semantic.success : null,
        ),
      ),
    );
  }
}

/// Void needs a reason (at least 3 characters) and cannot be undone.
class _VoidDialog extends StatefulWidget {
  const _VoidDialog({required this.familyName});

  final String familyName;

  @override
  State<_VoidDialog> createState() => _VoidDialogState();
}

class _VoidDialogState extends State<_VoidDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final valid = _reason.text.trim().length >= 3;
    return AlertDialog(
      title: Text(l10n.reliefVoidTitle(widget.familyName)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reliefVoidBody),
          const SizedBox(height: 16),
          TextField(
            controller: _reason,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.reliefVoidReason,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          onPressed: valid
              ? () => Navigator.of(context).pop(_reason.text.trim())
              : null,
          child: Text(l10n.reliefVoidHandout),
        ),
      ],
    );
  }
}
