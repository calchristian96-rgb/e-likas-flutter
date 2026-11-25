import '../../../core/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/data_freshness_formatter.dart';
import '../../../core/widgets/error_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../family_registration/domain/repositories/pending_queue_repository.dart';
import '../../family_registration/presentation/providers/pending_queue_provider.dart';
import '../domain/pending_action.dart';
import 'outbox_providers.dart';
import 'sent_list.dart';
import '../../../core/network/staff_api_error_mapper.dart';
import '../../../core/widgets/lock_note.dart';

/// Everything this device still has to send: the answer first (how many
/// wait, how many need a look), one primary button (Sync now), and the
/// rows that need attention, each with Try again / Discard in "...".
/// The Sent tab lists what this phone already sent for the event, so a
/// record that left the queue can still be found and corrected.
class SyncPage extends ConsumerStatefulWidget {
  const SyncPage({super.key, this.initialTab = 0});

  /// 0: To send; 1: Sent.
  final int initialTab;

  @override
  ConsumerState<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends ConsumerState<SyncPage> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final l10n = AppLocalizations.of(context);
    // Its own message below, not the automatic-send snackbar.
    final result = await ref.read(staffSyncAllProvider)(automatic: false);
    if (!mounted) return;
    setState(() => _syncing = false);
    final text = result.stoppedForAuth
        ? l10n.staffSyncStoppedForAuthMessage
        : result.wasOffline
        ? l10n.staffSyncRequiresConnectionMessage
        : l10n.syncSentMessage(result.sent);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _discard(PendingAction action) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.syncDiscardTitle),
        content: Text(l10n.syncDiscardBody(action.summary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.syncDiscardConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(outboxRepositoryProvider).delete(action.localId);
    ref.read(outboxRevisionProvider.notifier).bump();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.syncDiscarded)));
    }
  }

  Future<void> _retry(PendingAction action) async {
    await ref.read(outboxRepositoryProvider).retry(action.localId);
    ref.read(outboxRevisionProvider.notifier).bump();
    await _syncNow();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actionsAsync = ref.watch(pendingActionsProvider);
    final registrations = ref.watch(pendingQueueCountsProvider).value;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab.clamp(0, 1),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.syncTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.syncTabToSend),
              Tab(text: l10n.syncTabSent),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _toSend(context, actionsAsync, registrations),
            const SentList(),
          ],
        ),
      ),
    );
  }

  Widget _toSend(
    BuildContext context,
    AsyncValue<List<PendingAction>> actionsAsync,
    PendingQueueCounts? registrations,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return actionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: ErrorState(
          message: l10n.syncCouldNotRead,
          onRetry: () => ref.invalidate(pendingActionsProvider),
        ),
      ),
      data: (actions) {
        final attention = [
          for (final a in actions)
            if (a.needsAttention) a,
        ];
        final waiting = [
          for (final a in actions)
            if (!a.needsAttention) a,
        ];
        final regWaiting = registrations?.pending ?? 0;
        final regAttention = registrations?.needsAttention ?? 0;
        final totalWaiting = waiting.length + regWaiting;
        final totalAttention = attention.length + regAttention;
        return RefreshIndicator(
          onRefresh: _syncNow,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: pagePadding(context),
            children: [
              Text(
                totalWaiting == 0 && totalAttention == 0
                    ? l10n.syncAllDone
                    : l10n.syncWaitingCount(totalWaiting),
                style: theme.textTheme.titleLarge,
              ),
              if (totalAttention > 0)
                Text(
                  l10n.syncAttentionCount(totalAttention),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _syncing ? null : _syncNow,
                icon: _syncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(l10n.syncNow),
              ),
              if (attention.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  l10n.syncNeedsAttention,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final a in attention)
                  _ActionTile(
                    action: a,
                    onRetry: () => _retry(a),
                    onDiscard: () => _discard(a),
                  ),
              ],
              if (waiting.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(l10n.syncWaiting, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final a in waiting) _ActionTile(action: a),
              ],
              if (regWaiting + regAttention > 0) ...[
                const SizedBox(height: 24),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    minTileHeight: 56,
                    title: Text(l10n.syncFamilyRegistrations),
                    subtitle: Text(
                      l10n.syncWaitingCount(regWaiting + regAttention),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.push('/staff/more/pending-registrations'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action, this.onRetry, this.onDiscard});

  final PendingAction action;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        minTileHeight: 56,
        title: Text(action.summary),
        // A lock answer (the event is monitored or closed) is shown with
        // the lock look, not as an error (0.4.0 Part 1).
        subtitle:
            action.lastErrorMessage != null &&
                eventLockKindOf(action.lastErrorMessage!, const {}) != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: LockNote(message: action.lastErrorMessage, dense: true),
              )
            : Text(
                action.lastErrorMessage ?? formatElapsedSince(action.createdAt),
                style: action.needsAttention
                    ? theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      )
                    : null,
              ),
        trailing: onRetry == null
            ? const Icon(Icons.schedule)
            : MoreButton(
                title: action.summary,
                actions: [
                  SheetAction(
                    label: l10n.syncTryAgain,
                    icon: Icons.refresh,
                    onTap: onRetry!,
                  ),
                  SheetAction(
                    label: l10n.syncDiscardConfirm,
                    icon: Icons.delete_outline,
                    destructive: true,
                    onTap: onDiscard!,
                  ),
                ],
              ),
      ),
    );
  }
}
