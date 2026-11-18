import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/stat_strip.dart';
import '../../core/widgets/ui_kit.dart';
import '../../l10n/app_localizations.dart';
import '../barangay_status/presentation/barangay_status_card.dart'
    show barangayStatusColor;
import '../barangay_status/staff/barangay_page.dart';
import '../box_relief/relief_page.dart';
import '../box_relief/round_families_page.dart';
import '../count_submissions/final_count_card.dart';
import '../monitoring/monitoring_page.dart';
import '../outbox/domain/pending_action.dart';
import '../private_houses/private_houses.dart';
import '../outbox/presentation/outbox_providers.dart';
import '../staff_auth/domain/entities/staff_session.dart';
import '../staff_shell/current_event.dart';

/// Families of the latest round still without a box, or null with no
/// round (or nothing known yet).
final familiesWithoutBoxProvider = FutureProvider.autoDispose<int?>((
  ref,
) async {
  final boxes = await ref.watch(barangayBoxesProvider.future);
  final round = boxes?.boxes.latestRound;
  if (round == null) return null;
  final families = await ref.watch(roundFamiliesProvider(round.id).future);
  return [
    for (final g in families.data.puroks)
      for (final f in g.families)
        if (!f.given) f,
  ].length;
});

/// The barangay official's home (Part 3.3): the event and the barangay's
/// status with quick Watch / Flooding reported, the numbers that decide
/// what to do, three big buttons, a To do list and the sync state.
class OfficialHomePage extends ConsumerWidget {
  const OfficialHomePage({super.key, required this.session});

  final StaffSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final overview = ref.watch(monitoringSectionProvider('overview')).value;
    final figures =
        overview?.data?['figures'] as Map<String, dynamic>? ?? const {};
    int? n(String k) => (figures[k] as num?)?.toInt();
    final boxes = ref.watch(barangayBoxesProvider).value?.boxes;
    final round = boxes?.latestRound;
    final withoutBox = ref.watch(familiesWithoutBoxProvider).value;
    final count = ref.watch(computedCountProvider).value?.count;
    final sync = ref.watch(syncSummaryProvider).value;

    final todo = <Widget>[
      if (withoutBox != null && withoutBox > 0 && round != null)
        _TodoCard(
          icon: Icons.inventory_2_outlined,
          text: l10n.homeTodoWithoutBox(withoutBox),
          onTap: () => context.go('/staff/relief/round/${round.id}'),
        ),
      if (count != null &&
          count.eventActive &&
          (count.submitted == null ||
              count.hasLateEntries ||
              count.changedSinceSubmission))
        _TodoCard(
          icon: count.hasLateEntries
              ? Icons.schedule
              : Icons.fact_check_outlined,
          text: count.submitted == null
              ? l10n.homeTodoFinalCountNotSent
              : count.hasLateEntries
              ? l10n.lateEntriesTodo(count.lateEntries!.total)
              : l10n.finalCountChanged,
          onTap: () => context.go('/staff/home/barangay'),
        ),
      if ((sync?.needAttention ?? 0) > 0)
        _TodoCard(
          icon: Icons.error_outline,
          text: l10n.syncAttentionCount(sync!.needAttention),
          onTap: () => context.go('/staff/more/sync'),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          session.barangayName == null
              ? l10n.staffTabHome
              : l10n.residentBarangayStatusOf(session.barangayName!),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(monitoringSectionProvider('overview'));
          ref.invalidate(ownSituationProvider);
          ref.invalidate(barangayBoxesProvider);
          await ref.read(staffSyncAllProvider)();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding(context),
          children: [
            // In the body, not the app bar: the barangay name keeps its
            // room at a large font size.
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: SyncChip(),
            ),
            const SizedBox(height: 8),
            const StaffEventBar(),
            const SizedBox(height: 16),
            _QuickStatusCard(session: session),
            const SizedBox(height: 16),
            StatStrip(
              items: [
                StatItem(l10n.homeEvacueesHere, '${n('inside') ?? '–'}'),
                StatItem(l10n.monitoringFamilies, '${n('families') ?? '–'}'),
                StatItem(
                  l10n.homeWithoutBox,
                  withoutBox == null ? '–' : '$withoutBox',
                  alert: (withoutBox ?? 0) > 0,
                ),
                StatItem(
                  l10n.homeBoxesLeft,
                  round == null ? '–' : '${round.figures.leftToGive}',
                ),
              ],
            ),
            if (session.barangayId != null) ...[
              const SizedBox(height: 8),
              PrivateHousesCard(
                barangayId: session.barangayId!,
                onOpen: () => context.go(
                  '/staff/home/private-houses/${session.barangayId}',
                ),
              ),
            ],
            const SizedBox(height: 16),
            _BigButton(
              icon: Icons.person_add_alt_1_outlined,
              label: l10n.registerTitle,
              onTap: () => context.push('/staff/register'),
            ),
            const SizedBox(height: 8),
            _BigButton(
              icon: Icons.how_to_reg_outlined,
              label: l10n.homeCheckInOut,
              onTap: () => context.go('/staff/centers'),
            ),
            const SizedBox(height: 8),
            _BigButton(
              icon: Icons.inventory_2_outlined,
              label: l10n.homeGiveBox,
              onTap: () => context.go(
                round == null
                    ? '/staff/relief'
                    : '/staff/relief/round/${round.id}',
              ),
            ),
            SectionTitle(l10n.homeTodo),
            if (todo.isEmpty)
              EmptyNote(
                icon: Icons.check_circle_outline,
                message: l10n.homeTodoNone,
              )
            else
              for (final t in todo) ...[t, const SizedBox(height: 8)],
          ],
        ),
      ),
    );
  }
}

/// The barangay's status, and Watch / Flooding reported one tap away
/// (queued offline, like every status change).
class _QuickStatusCard extends ConsumerWidget {
  const _QuickStatusCard({required this.session});

  final StaffSession session;

  Future<void> _set(
    BuildContext context,
    WidgetRef ref,
    OwnSituation s,
    SituationStatusOption option,
  ) async {
    final l10n = AppLocalizations.of(context);
    await enqueueStaffAction(
      ref,
      kind: PendingActionKind.barangayStatus,
      method: 'POST',
      path: '/gis/barangay-status',
      body: {
        'evacuation_event_id': s.eventId,
        'barangay_id': session.barangayId,
        'status': option.key,
      },
      summary: option.label,
      subjectKey: 'barangay:${session.barangayId}:status',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.barangayStatusSaved(option.label))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = ref.watch(ownSituationProvider).value?.situation;
    final queued = (ref.watch(pendingActionsProvider).value ?? const [])
        .where((a) => a.kind == PendingActionKind.barangayStatus)
        .toList();
    if (s == null) return const SizedBox.shrink();
    final label = queued.isEmpty ? s.label : queued.last.summary;
    final quick = [
      for (final o in s.options)
        if (o.maySet &&
            (o.key == 'watch' || o.key == 'flooding_reported') &&
            o.key != s.status)
          o,
    ];
    return AppCard(
      onTap: () => context.go('/staff/home/barangay'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.homeBarangayStatus, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          StatusChip(
            label: label,
            color: barangayStatusColor(context, s.status),
          ),
          if (queued.isEmpty) EvacuationOrderLine(order: s.order),
          if (s.open && s.mayUpdate && quick.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in quick)
                  OutlinedButton(
                    onPressed: () => _set(context, ref, s, o),
                    child: Text(o.label),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}

class _TodoCard extends StatelessWidget {
  const _TodoCard({required this.icon, required this.text, this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

/// "3 waiting to send" / "All sent": the sync state, one tap from Sync.
class SyncChip extends ConsumerWidget {
  const SyncChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(syncSummaryProvider).value;
    if (s == null) return const SizedBox.shrink();
    final waiting = s.waiting + s.needAttention;
    return ActionChip(
      avatar: Icon(
        waiting == 0 ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
        size: 18,
      ),
      label: Text(
        waiting == 0 ? l10n.syncAllSent : l10n.syncWaitingToSend(waiting),
      ),
      onPressed: () => context.go('/staff/more/sync'),
    );
  }
}
