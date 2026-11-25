import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/sent_record.dart';
import 'sent_providers.dart';

/// Sync > Sent: what this phone sent for the selected event, newest
/// first (14 days, at most 200). A registration or an EC Board person
/// has Edit (online only, corrected on the server); queued actions have
/// no edit on the server and are listed read-only.
class SentList extends ConsumerWidget {
  const SentList({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    SentRecord record,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (!await ref.read(connectivityServiceProvider).hasConnection) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sentEditNeedsConnection)));
      return;
    }
    if (!context.mounted) return;
    final person = record.serverEvacueeId;
    await context.push(
      '/staff/more/sync/sent-family/${record.serverFamilyId}'
      '${person == null ? '' : '?person=$person'}',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sentAsync = ref.watch(sentRecordsProvider);
    return sentAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: ErrorState(
          message: l10n.syncCouldNotRead,
          onRetry: () => ref.invalidate(sentRecordsProvider),
        ),
      ),
      data: (records) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(sentRecordsProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding(context),
          children: [
            Text(
              l10n.sentIntro,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (records.isEmpty)
              EmptyNote(icon: Icons.outbox_outlined, message: l10n.sentEmpty)
            else
              for (final r in records)
                _SentTile(
                  record: r,
                  onEdit: r.canEdit ? () => _edit(context, ref, r) : null,
                ),
          ],
        ),
      ),
    );
  }
}

/// The line shown for a sent record.
String sentRecordTitle(AppLocalizations l10n, SentRecord r) => switch (r.kind) {
  SentRecordKind.registration => l10n.sentFamilySummary(
    r.summary,
    r.memberCount ?? 1,
  ),
  SentRecordKind.ecBoardEntry => l10n.sentPersonAdded(r.summary),
  SentRecordKind.action => r.summary,
};

class _SentTile extends StatelessWidget {
  const _SentTile({required this.record, this.onEdit});

  final SentRecord record;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final when = l10n.sentAgo(formatAgo(l10n, record.sentAt));
    final place = record.place;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        minTileHeight: 56,
        leading: Icon(switch (record.kind) {
          SentRecordKind.registration => Icons.family_restroom_outlined,
          SentRecordKind.ecBoardEntry => Icons.person_add_alt_outlined,
          SentRecordKind.action => Icons.task_alt_outlined,
        }),
        title: Text(sentRecordTitle(l10n, record)),
        subtitle: Text(place == null ? when : '$place · $when'),
        trailing: onEdit == null
            ? null
            : TextButton(onPressed: onEdit, child: Text(l10n.sentEdit)),
      ),
    );
  }
}
