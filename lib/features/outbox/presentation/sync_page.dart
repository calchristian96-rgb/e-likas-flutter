import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/data_freshness_formatter.dart';
import '../../../core/widgets/error_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../family_registration/presentation/providers/pending_queue_provider.dart';
import '../domain/pending_action.dart';
import 'outbox_providers.dart';

/// Everything this device still has to send: the answer first (how many
/// wait, how many need a look), one primary button (Sync now), and the
/// rows that need attention, each with Try again / Discard in "...".
class SyncPage extends ConsumerStatefulWidget {
  const SyncPage({super.key});

  @override
  ConsumerState<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends ConsumerState<SyncPage> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final l10n = AppLocalizations.of(context);
    final result = await ref.read(staffSyncAllProvider)();
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
    final theme = Theme.of(context);
    final actionsAsync = ref.watch(pendingActionsProvider);
    final registrations = ref.watch(pendingQueueCountsProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncTitle)),
      body: actionsAsync.when(
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
              padding: const EdgeInsets.all(16),
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
      ),
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
        subtitle: Text(
          action.lastErrorMessage ?? formatElapsedSince(action.createdAt),
          style: action.needsAttention
              ? theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                )
              : null,
        ),
        trailing: onRetry == null
            ? const Icon(Icons.schedule)
            : PopupMenuButton<String>(
                tooltip: l10n.moreActions,
                onSelected: (v) => v == 'retry' ? onRetry!() : onDiscard!(),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'retry', child: Text(l10n.syncTryAgain)),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'discard',
                    child: Text(
                      l10n.syncDiscardConfirm,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
