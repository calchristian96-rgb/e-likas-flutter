import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../staff_auth/presentation/widgets/staff_auth_guard.dart';
import '../../domain/entities/pending_registration.dart';
import '../../domain/entities/pending_registration_status.dart';
import '../providers/pending_queue_provider.dart';

class PendingRegistrationsPage extends StatelessWidget {
  const PendingRegistrationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffAuthGuard(
      builder: (context, session) => const _PendingRegistrationsBody(),
    );
  }
}

class _PendingRegistrationsBody extends ConsumerStatefulWidget {
  const _PendingRegistrationsBody();

  @override
  ConsumerState<_PendingRegistrationsBody> createState() =>
      _PendingRegistrationsBodyState();
}

class _PendingRegistrationsBodyState
    extends ConsumerState<_PendingRegistrationsBody> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _syncing = true);
    final result = await ref.read(staffSyncNowProvider)();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.stoppedForAuth
              ? l10n.staffSyncStoppedForAuthMessage
              : l10n.staffSyncCompletedMessage(result.processed),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final registrationsAsync = ref.watch(pendingRegistrationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.staffWorkspacePendingRegistrations),
        actions: [
          IconButton(
            icon: _syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_outlined),
            tooltip: l10n.staffWorkspaceSyncNow,
            onPressed: _syncing ? null : _syncNow,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: FilledButton.icon(
              // Always visible — online, offline, empty queue,
              // populated queue, or a sync error — registering a new
              // family never depends on this list's own load state.
              onPressed: () => context.push('/settings/staff/register-family'),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(l10n.staffWorkspaceRegisterFamily),
            ),
          ),
          Expanded(
            child: registrationsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.staffPendingListEmpty,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _PendingRegistrationTile(summary: items[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: ErrorState(message: l10n.staffPendingListError),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingRegistrationTile extends StatelessWidget {
  const _PendingRegistrationTile({required this.summary});

  final PendingRegistrationSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Card(
      child: ListTile(
        onTap: () => context.push(
          '/settings/staff/pending-registrations/${summary.localId}',
        ),
        leading: _StatusIcon(status: summary.status),
        title: Text(
          summary.headOfFamilyName.isEmpty
              ? l10n.staffPendingNoHeadName
              : summary.headOfFamilyName,
        ),
        subtitle: Text(
          l10n.staffPendingSubtitle(
            summary.memberCount,
            summary.barangayName,
            dateFormat.format(summary.createdAt),
          ),
        ),
        trailing: _StatusChip(status: summary.status),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final PendingRegistrationStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (status) {
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
    };
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
