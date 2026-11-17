import '../../core/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_theme.dart';
import '../../core/cache/staff_read_cache.dart';
import '../../core/utils/data_freshness_formatter.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/stat_strip.dart';
import '../../l10n/app_localizations.dart';
import '../outbox/domain/pending_action.dart';
import '../outbox/presentation/outbox_providers.dart';
import '../staff_shell/current_event.dart';
import 'box_relief_models.dart';

/// `GET /box-relief/barangay` for the current event, saved for offline.
final barangayBoxesProvider =
    FutureProvider.autoDispose<
      ({BarangayBoxes boxes, DateTime fetchedAt, bool fromCache})?
    >((ref) async {
      ref.watch(outboxRevisionProvider);
      final event = await ref.watch(currentStaffEventProvider.future);
      if (event == null) return null;
      final read = await ref
          .watch(staffReadCacheProvider)
          .get(
            '/box-relief/barangay',
            query: {'evacuation_event_id': event.id},
          );
      return (
        boxes: BarangayBoxes.fromJson(read.data),
        fetchedAt: read.fetchedAt,
        fromCache: read.isFromCache,
      );
    });

/// Relief boxes for the official's barangay (C21): the latest round's
/// figures first, then the boxes sent that still need counting, then the
/// rounds (each opens its families by purok).
class ReliefPage extends ConsumerWidget {
  const ReliefPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(barangayBoxesProvider);
    final queued = ref.watch(pendingActionsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reliefTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(barangayBoxesProvider);
          await ref.read(staffSyncAllProvider)();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding(context),
          children: [
            const StaffEventBar(),
            const SizedBox(height: 16),
            ...async.when(
              loading: () => [const Center(child: CircularProgressIndicator())],
              error: (_, _) => [
                ErrorState(
                  message: l10n.reliefNeedsConnectionFirst,
                  onRetry: () => ref.invalidate(barangayBoxesProvider),
                ),
              ],
              data: (result) {
                if (result == null) return [Text(l10n.staffNoOpenEvent)];
                final boxes = result.boxes;
                final round = boxes.latestRound;
                final waiting = [
                  for (final r in boxes.rounds)
                    for (final d in r.dispatches)
                      if (d.waitingForConfirmation) (r, d),
                ];
                return [
                  if (result.fromCache)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l10n.savedCopyAge(formatElapsedSince(result.fetchedAt)),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  if (!boxes.countValidated)
                    _Callout(text: l10n.reliefCountNotValidated),
                  if (round == null)
                    Text(l10n.reliefNoRoundYet)
                  else ...[
                    Text(
                      l10n.reliefRound(round.roundNumber),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    StatStrip(
                      items: [
                        StatItem(l10n.reliefNeed, '${round.figures.need}'),
                        StatItem(
                          l10n.reliefReceived,
                          '${round.figures.received}',
                        ),
                        StatItem(l10n.reliefGiven, '${round.figures.given}'),
                        StatItem(
                          l10n.reliefShort,
                          '${round.figures.short}',
                          alert: round.figures.short > 0,
                        ),
                      ],
                    ),
                  ],
                  if (round != null)
                    _ShortfallSection(
                      round: round,
                      canRequest: boxes.canRequestShortfall,
                      queued: queued.any(
                        (a) => a.subjectKey == 'shortfall:${round.id}',
                      ),
                    ),
                  if (waiting.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      l10n.reliefBoxesToConfirm,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final (r, d) in waiting)
                      _DispatchCard(
                        round: r,
                        dispatch: d,
                        canAct: boxes.canAct,
                        queued: queued.any(
                          (a) => a.subjectKey == 'dispatch:${d.id}',
                        ),
                      ),
                  ],
                  if (boxes.rounds.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      l10n.reliefGiveBoxes,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final r in boxes.rounds.reversed)
                            ListTile(
                              minTileHeight: 56,
                              title: Text(l10n.reliefRound(r.roundNumber)),
                              subtitle: Text(
                                l10n.reliefGivenOfReceived(
                                  r.figures.given,
                                  r.figures.received,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () =>
                                  context.push('/staff/relief/round/${r.id}'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning = theme.extension<AppSemanticColors>()!.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warning),
      ),
      child: Text(text, style: theme.textTheme.bodyMedium),
    );
  }
}

class _DispatchCard extends ConsumerWidget {
  const _DispatchCard({
    required this.round,
    required this.dispatch,
    required this.canAct,
    required this.queued,
  });

  final BoxRound round;
  final BoxDispatch dispatch;
  final bool canAct;
  final bool queued;

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<(int, String?)>(
      context: context,
      builder: (_) => _ConfirmDialog(sent: dispatch.quantity),
    );
    if (result == null) return;
    final (count, note) = result;
    await enqueueStaffAction(
      ref,
      kind: PendingActionKind.dispatchConfirm,
      method: 'POST',
      path: '/box-relief/dispatches/${dispatch.id}/confirm',
      body: {'confirmed_quantity': count, 'note': ?note},
      summary: l10n.reliefConfirmSummary(
        l10n.countBoxes(count),
        round.roundNumber,
      ),
      subjectKey: 'dispatch:${dispatch.id}',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sentOn = dispatch.dispatchedAt == null
        ? ''
        : DateFormat.yMMMd().add_jm().format(dispatch.dispatchedAt!);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.reliefBoxesSent(
                l10n.countBoxes(dispatch.quantity),
                round.roundNumber,
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (sentOn.isNotEmpty) Text(sentOn),
            const SizedBox(height: 8),
            if (queued)
              Text(l10n.syncWaiting)
            else if (canAct)
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => _confirm(context, ref),
                child: Text(l10n.reliefConfirmArrived),
              ),
          ],
        ),
      ),
    );
  }
}

/// How many boxes actually arrived; a note is required when fewer.
class _ConfirmDialog extends StatefulWidget {
  const _ConfirmDialog({required this.sent});

  final int sent;

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  late final _count = TextEditingController(text: '${widget.sent}');
  final _note = TextEditingController();

  int? get _value => int.tryParse(_count.text);
  bool get _fewer => (_value ?? widget.sent) < widget.sent;
  bool get _valid =>
      _value != null &&
      _value! >= 0 &&
      _value! <= widget.sent &&
      (!_fewer || _note.text.trim().isNotEmpty);

  @override
  void dispose() {
    _count.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.reliefHowManyArrived),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _count,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.reliefBoxesArrived(widget.sent),
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_fewer) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              decoration: InputDecoration(
                labelText: l10n.reliefFewerNote,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _valid
              ? () => Navigator.of(
                  context,
                ).pop((_value!, _fewer ? _note.text.trim() : null))
              : null,
          child: Text(l10n.reliefConfirm),
        ),
      ],
    );
  }
}

/// The round's shortfall (C23b): the requests already made, and "Request
/// N more boxes" up to what the server allows (`can_request`), queued.
class _ShortfallSection extends ConsumerWidget {
  const _ShortfallSection({
    required this.round,
    required this.canRequest,
    required this.queued,
  });

  final BoxRound round;
  final bool canRequest;
  final bool queued;

  Future<void> _request(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final max = round.figures.canRequest;
    var quantity = max;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.reliefShortfallTitle(round.roundNumber)),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.outlined(
                tooltip: l10n.decrease,
                onPressed: quantity > 1
                    ? () => setState(() => quantity--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton.outlined(
                tooltip: l10n.increase,
                onPressed: quantity < max
                    ? () => setState(() => quantity++)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.reliefShortfallSend),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await enqueueStaffAction(
      ref,
      kind: PendingActionKind.shortfallRequest,
      method: 'POST',
      path: '/box-relief/rounds/${round.id}/shortfall-requests',
      body: {'quantity': quantity},
      summary: l10n.reliefShortfallSummary(quantity, round.roundNumber),
      subjectKey: 'shortfall:${round.id}',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final requests = round.shortfallRequests;
    if (requests.isEmpty && !queued && round.figures.canRequest <= 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in requests)
            Text(
              l10n.reliefShortfallRow(r.quantity, switch (r.status) {
                'approved' => l10n.requestStatusApproved,
                'rejected' => l10n.requestStatusRejected,
                'fulfilled' => l10n.requestStatusFulfilled,
                _ => l10n.requestStatusWaiting,
              }),
              style: theme.textTheme.bodyMedium,
            ),
          if (queued) Text(l10n.syncWaiting, style: theme.textTheme.bodySmall),
          if (canRequest && !queued && round.figures.canRequest > 0) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => _request(context, ref),
              child: Text(l10n.reliefShortfallAsk(round.figures.canRequest)),
            ),
          ],
        ],
      ),
    );
  }
}
