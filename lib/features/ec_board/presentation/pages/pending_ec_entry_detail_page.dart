import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../family_registration/domain/entities/pending_registration_status.dart';
import '../../../staff_auth/presentation/widgets/staff_auth_guard.dart';
import '../../domain/entities/pending_ec_board_entry.dart';
import '../providers/ec_board_provider.dart';
import 'add_evacuee_form_page.dart';

/// Review/Edit screen for one queued EC Board entry — mirrors
/// `PendingRegistrationDetailPage` exactly, one dataset smaller.
class PendingEcEntryDetailPage extends StatelessWidget {
  const PendingEcEntryDetailPage({super.key, required this.localId});

  final String localId;

  @override
  Widget build(BuildContext context) {
    return StaffAuthGuard(
      builder: (context, session) => _Body(localId: localId),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.localId});

  final String localId;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  void _refreshEverything(int centerId) {
    ref.invalidate(ecBoardEntryDetailProvider(widget.localId));
    ref.invalidate(ecBoardEntriesForCenterProvider(centerId));
    ref.invalidate(ecBoardCountsForCenterProvider(centerId));
  }

  Future<void> _openEdit(PendingEcBoardEntryDetail detail) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AddEvacueeFormPage(
          centerId: detail.draft.evacuationCenterId,
          evacuationEventId: detail.draft.evacuationEventId!,
          editingLocalId: detail.summary.localId,
          initialDraft: detail.draft,
          initialHouseholdLabel: detail.summary.householdLabel,
        ),
      ),
    );
    if (!mounted) return;
    _refreshEverything(detail.draft.evacuationCenterId);
  }

  Future<void> _delete(PendingEcBoardEntryDetail detail) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.staffPendingDetailDeleteDialogTitle),
        content: Text(l10n.staffPendingDetailDeleteDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.staffPendingDetailDeleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final centerId = detail.draft.evacuationCenterId;
    await ref.read(ecBoardRepositoryProvider).delete(widget.localId);
    if (!mounted) return;
    ref.invalidate(ecBoardEntriesForCenterProvider(centerId));
    ref.invalidate(ecBoardCountsForCenterProvider(centerId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.staffPendingDetailDeletedMessage)),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detailAsync = ref.watch(ecBoardEntryDetailProvider(widget.localId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ecBoardEntryDetailTitle)),
      body: SafeArea(
        child: detailAsync.when(
          data: (detail) {
            if (detail == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.staffPendingDetailNotFound,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return _DetailBody(
              detail: detail,
              busy: _busy,
              onEdit: () => _openEdit(detail),
              onDelete: () => _delete(detail),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ErrorState(
                message: l10n.staffPendingDetailLoadError,
                onRetry: () =>
                    ref.invalidate(ecBoardEntryDetailProvider(widget.localId)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.detail,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final PendingEcBoardEntryDetail detail;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final summary = detail.summary;
    final dateFormat = DateFormat.yMMMd().add_jm();
    final isSyncing = summary.status == PendingRegistrationStatus.syncing;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                summary.householdLabel,
                style: theme.textTheme.headlineSmall,
              ),
            ),
            _StatusChip(status: summary.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.staffPendingDetailCreatedAt(
            dateFormat.format(summary.createdAt),
          ),
          style: theme.textTheme.bodySmall,
        ),
        if (isSyncing) ...[
          const SizedBox(height: 12),
          Text(
            l10n.staffPendingDetailSyncingNotice,
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ],
        if (summary.status == PendingRegistrationStatus.needsAttention) ...[
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (summary.lastErrorMessage != null)
                    Text(summary.lastErrorMessage!),
                  const SizedBox(height: 4),
                  Text(
                    l10n.staffPendingDetailAttemptCount(summary.attemptCount),
                  ),
                ],
              ),
            ),
          ),
        ],
        const Divider(height: 32),
        _Row(
          label: l10n.ecBoardFieldSex,
          value: summary.sex == 'female'
              ? l10n.staffRegSexFemale
              : l10n.staffRegSexMale,
        ),
        _Row(
          label: l10n.ecBoardFieldAgeBracket,
          value: summary.ageBracket == null
              ? l10n.ecBoardUnclassifiedLabel
              : localizedAgeBracket(context, summary.ageBracket!),
        ),
        _Row(label: l10n.ecBoardFieldHousehold, value: summary.householdLabel),
        if (detail.draft.existingFamilyLocalId != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.ecBoardPendingHouseholdNotice,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: busy || isSyncing ? null : onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: Text(l10n.staffPendingDetailEditButton),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: busy || isSyncing ? null : onDelete,
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline),
          label: Text(l10n.staffPendingDetailDeleteButton),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(color: theme.colorScheme.error),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final PendingRegistrationStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      PendingRegistrationStatus.pending => (
        l10n.staffStatusPending,
        colorScheme.onSurfaceVariant,
      ),
      PendingRegistrationStatus.syncing => (
        l10n.staffStatusSyncing,
        colorScheme.primary,
      ),
      PendingRegistrationStatus.needsAttention => (
        l10n.staffStatusNeedsAttention,
        colorScheme.error,
      ),
    };
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.08),
      side: BorderSide.none,
    );
  }
}
