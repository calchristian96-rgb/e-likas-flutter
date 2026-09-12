import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../staff_auth/presentation/widgets/staff_auth_guard.dart';
import '../../domain/entities/family_member_draft.dart';
import '../../domain/entities/pending_registration.dart';
import '../../domain/entities/pending_registration_status.dart';
import '../providers/lookup_providers.dart';
import '../providers/pending_queue_provider.dart';
import 'family_registration_form_page.dart';

/// Review/Edit screen for one queued registration — reachable from the
/// Pending Registrations list. Shows everything staff need to decide
/// what to do next (status, why it needs attention, the full draft),
/// then hands off the actual editing to [FamilyRegistrationFormPage]'s
/// existing edit mode rather than duplicating its fields here.
class PendingRegistrationDetailPage extends StatelessWidget {
  const PendingRegistrationDetailPage({super.key, required this.localId});

  final String localId;

  @override
  Widget build(BuildContext context) {
    return StaffAuthGuard(
      builder: (context, session) =>
          _PendingRegistrationDetailBody(localId: localId),
    );
  }
}

class _PendingRegistrationDetailBody extends ConsumerStatefulWidget {
  const _PendingRegistrationDetailBody({required this.localId});

  final String localId;

  @override
  ConsumerState<_PendingRegistrationDetailBody> createState() =>
      _PendingRegistrationDetailBodyState();
}

class _PendingRegistrationDetailBodyState
    extends ConsumerState<_PendingRegistrationDetailBody> {
  bool _busy = false;

  void _refreshEverything() {
    ref.invalidate(pendingRegistrationDetailProvider(widget.localId));
    ref.invalidate(pendingRegistrationsProvider);
    ref.invalidate(pendingQueueCountsProvider);
  }

  Future<void> _openEdit(PendingRegistrationDetail detail) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FamilyRegistrationFormPage(
          editingLocalId: detail.summary.localId,
          initialDraft: detail.draft,
          initialFieldErrors: detail.fieldErrors,
        ),
      ),
    );
    if (!mounted) return;
    // Covers every outcome of the edit screen — resubmitted
    // successfully (record now gone), saved offline again, or failed
    // again with new field errors — without needing to know which one
    // happened.
    _refreshEverything();
  }

  Future<void> _delete(PendingRegistrationDetail detail) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.staffPendingDetailDeleteDialogTitle),
        content: Text(
          detail.summary.lastErrorCategory == PendingErrorCategory.ambiguous
              ? '${l10n.staffPendingDetailDeleteDialogBody} ${l10n.staffPendingAmbiguousHint}'
              : l10n.staffPendingDetailDeleteDialogBody,
        ),
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
    await ref.read(pendingQueueRepositoryProvider).delete(widget.localId);
    if (!mounted) return;
    ref.invalidate(pendingRegistrationsProvider);
    ref.invalidate(pendingQueueCountsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.staffPendingDetailDeletedMessage)),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detailAsync = ref.watch(
      pendingRegistrationDetailProvider(widget.localId),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.staffPendingDetailTitle)),
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
                onRetry: () => ref.invalidate(
                  pendingRegistrationDetailProvider(widget.localId),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.detail,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final PendingRegistrationDetail detail;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final summary = detail.summary;
    final draft = detail.draft;
    final dateFormat = DateFormat.yMMMd().add_jm();
    final isSyncing = summary.status == PendingRegistrationStatus.syncing;

    final eventsAsync = ref.watch(evacuationEventsLookupProvider);
    final centersAsync = ref.watch(evacuationCentersLookupProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                summary.headOfFamilyName.isEmpty
                    ? l10n.staffPendingNoHeadName
                    : summary.headOfFamilyName,
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
        Text(
          l10n.staffPendingDetailUpdatedAt(
            dateFormat.format(summary.updatedAt),
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
          _ErrorCard(summary: summary, fieldErrors: detail.fieldErrors),
        ],
        const Divider(height: 32),
        Text(
          l10n.staffPendingDetailSummarySectionTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _SummaryRow(
          label: l10n.staffRegFieldBarangay,
          value: summary.barangayName,
        ),
        if (draft.homeAddress != null && draft.homeAddress!.isNotEmpty)
          _SummaryRow(
            label: l10n.staffRegFieldHomeAddress,
            value: draft.homeAddress!,
          ),
        _SummaryRow(
          label: l10n.staffRegFieldEvacuationEvent,
          value: eventsAsync.maybeWhen(
            data: (events) => _lookupName(
              events.map((e) => (e.id, e.name)),
              draft.evacuationEventId,
            ),
            orElse: () => _fallbackLabel(draft.evacuationEventId),
          ),
        ),
        _SummaryRow(
          label: l10n.staffRegFieldDisplacementType,
          value: switch (draft.displacementType) {
            'inside_center' => l10n.staffRegDisplacementInsideCenter,
            'outside_center' => l10n.staffRegDisplacementOutsideCenter,
            _ => l10n.staffRegNotSpecified,
          },
        ),
        if (draft.displacementType == 'inside_center')
          _SummaryRow(
            label: l10n.staffRegFieldEvacuationCenter,
            value: centersAsync.maybeWhen(
              data: (centers) => _lookupName(
                centers.map((c) => (c.id, c.name)),
                draft.evacuationCenterId,
              ),
              orElse: () => _fallbackLabel(draft.evacuationCenterId),
            ),
          ),
        _SummaryRow(
          label: l10n.staffReg4psBeneficiaryLabel,
          value: draft.is4psBeneficiary
              ? l10n.staffRegIs4psMember
              : l10n.staffRegNotSpecified,
        ),
        const Divider(height: 32),
        Text(
          l10n.staffRegMembersSectionTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final member in draft.members)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MemberTile(member: member),
          ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: busy || isSyncing ? null : onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: Text(
            summary.status == PendingRegistrationStatus.needsAttention
                ? l10n.staffPendingDetailReviewButton
                : l10n.staffPendingDetailEditButton,
          ),
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

  static String _lookupName(Iterable<(int, String)> entries, int? id) {
    if (id == null) return '—';
    for (final (entryId, name) in entries) {
      if (entryId == id) return name;
    }
    return _fallbackLabel(id);
  }

  static String _fallbackLabel(int? id) => id == null ? '—' : '#$id';
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.summary, required this.fieldErrors});

  final PendingRegistrationSummary summary;
  final Map<String, List<String>> fieldErrors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat.yMMMd().add_jm();
    final category = summary.lastErrorCategory;

    return Card(
      color: colorScheme.errorContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.staffPendingDetailErrorSectionTitle,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: colorScheme.error),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (category != null)
              Text(
                _categoryLabel(l10n, category),
                style: TextStyle(color: colorScheme.error),
              ),
            if (summary.lastErrorMessage != null) ...[
              const SizedBox(height: 4),
              Text(summary.lastErrorMessage!),
            ],
            const SizedBox(height: 4),
            Text(l10n.staffPendingDetailAttemptCount(summary.attemptCount)),
            if (category == PendingErrorCategory.ambiguous) ...[
              const SizedBox(height: 8),
              Text(
                l10n.staffPendingAmbiguousHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (category == PendingErrorCategory.validation &&
                fieldErrors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.staffPendingDetailFieldErrorsTitle,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              for (final entry in fieldErrors.entries)
                for (final message in entry.value)
                  Text(
                    '• $message',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
            ],
            Builder(
              builder: (context) {
                final lastAttempt = summary.updatedAt;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.staffPendingDetailLastAttempt(
                      dateFormat.format(lastAttempt),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(
    AppLocalizations l10n,
    PendingErrorCategory category,
  ) => switch (category) {
    PendingErrorCategory.validation => l10n.staffPendingErrorCategoryValidation,
    PendingErrorCategory.forbidden => l10n.staffPendingErrorCategoryForbidden,
    PendingErrorCategory.ambiguous => l10n.staffPendingErrorCategoryAmbiguous,
    PendingErrorCategory.server => l10n.staffPendingErrorCategoryServer,
  };
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

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

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final FamilyMemberDraft member;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sexLabel = member.sex == 'female'
        ? l10n.staffRegSexFemale
        : l10n.staffRegSexMale;

    final flags = <String>[
      if (member.isPwd) l10n.staffRegIsPwd,
      if (member.isPregnant) l10n.staffRegIsPregnant,
      if (member.isLactating) l10n.staffRegIsLactating,
      if (member.isSoloParent) l10n.staffRegIsSoloParent,
      if (member.isIndigenousPerson) l10n.staffRegIsIndigenous,
      if (member.is4psBeneficiary) l10n.staffRegIs4psMember,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    member.fullName,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (member.isHeadOfFamily)
                  Chip(
                    label: Text(l10n.staffRegHeadOfFamilyBadge),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$sexLabel • ${member.dateOfBirth}',
              style: theme.textTheme.bodySmall,
            ),
            if (flags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final flag in flags)
                    Chip(
                      label: Text(flag),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ],
        ),
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
